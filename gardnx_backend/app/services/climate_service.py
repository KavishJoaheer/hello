"""Climate data service with Open-Meteo API integration and caching."""

import logging
import time
from typing import Dict, List, Optional

import httpx

logger = logging.getLogger("gardnx")

# Cache TTL in seconds (24 hours)
CACHE_TTL = 86400

MONTH_NAMES = [
    "", "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
]

# Mauritius fallback data when API is unavailable
MAURITIUS_FALLBACK = {
    1:  {"avg_temp": 27.0, "min_temp": 23.5, "max_temp": 30.5, "rainfall": 220, "humidity": 80},
    2:  {"avg_temp": 27.2, "min_temp": 23.5, "max_temp": 30.8, "rainfall": 230, "humidity": 81},
    3:  {"avg_temp": 26.5, "min_temp": 23.0, "max_temp": 30.0, "rainfall": 200, "humidity": 79},
    4:  {"avg_temp": 25.5, "min_temp": 22.0, "max_temp": 29.0, "rainfall": 130, "humidity": 76},
    5:  {"avg_temp": 23.5, "min_temp": 19.8, "max_temp": 27.2, "rainfall": 80, "humidity": 74},
    6:  {"avg_temp": 22.0, "min_temp": 18.5, "max_temp": 25.5, "rainfall": 60, "humidity": 72},
    7:  {"avg_temp": 21.2, "min_temp": 17.8, "max_temp": 24.6, "rainfall": 55, "humidity": 71},
    8:  {"avg_temp": 21.0, "min_temp": 17.5, "max_temp": 24.5, "rainfall": 50, "humidity": 70},
    9:  {"avg_temp": 21.8, "min_temp": 18.0, "max_temp": 25.5, "rainfall": 40, "humidity": 69},
    10: {"avg_temp": 23.2, "min_temp": 19.5, "max_temp": 27.0, "rainfall": 50, "humidity": 70},
    11: {"avg_temp": 25.0, "min_temp": 21.0, "max_temp": 28.8, "rainfall": 80, "humidity": 73},
    12: {"avg_temp": 26.5, "min_temp": 22.5, "max_temp": 30.0, "rainfall": 170, "humidity": 78},
}


def get_mauritius_season(month: int) -> str:
    """Return the major season name for a given month in Mauritius.

    Mauritius has two main seasons:
    - Summer (November - April): hot and humid, cyclone season
    - Winter (May - October): cool and dry
    """
    if month in (11, 12, 1, 2, 3, 4):
        return "summer"
    return "winter"


def get_sub_season(month: int) -> str:
    """Return a more granular sub-season label for Mauritius.

    Sub-seasons:
    - early_summer (November - December): warming up, pre-cyclone
    - peak_summer (January - March): hottest, cyclone risk
    - autumn_transition (April): cooling begins
    - early_winter (May - June): cool and dry setting in
    - peak_winter (July - September): coolest and driest
    - spring_transition (October): warming up
    """
    if month in (11, 12):
        return "early_summer"
    if month in (1, 2, 3):
        return "peak_summer"
    if month == 4:
        return "autumn_transition"
    if month in (5, 6):
        return "early_winter"
    if month in (7, 8, 9):
        return "peak_winter"
    return "spring_transition"  # October


def _gardening_notes(season: str, sub_season: str) -> str:
    """Return gardening tips based on the current season."""
    notes = {
        "early_summer": (
            "Start planting warm-season crops. Watch for heavy rains and "
            "prepare drainage. Good time for tomatoes, peppers, and beans."
        ),
        "peak_summer": (
            "Peak growing season. Water frequently and watch for pests. "
            "Cyclone season -- secure structures and protect young plants."
        ),
        "autumn_transition": (
            "Last chance for warm-season plantings. Begin planning cool-season crops. "
            "Harvest summer crops before temperatures drop."
        ),
        "early_winter": (
            "Ideal for cool-season vegetables: lettuce, cabbage, carrots. "
            "Reduce watering as rainfall decreases."
        ),
        "peak_winter": (
            "Coolest period. Focus on leafy greens, root vegetables, and herbs. "
            "Great time for soil preparation and composting."
        ),
        "spring_transition": (
            "Prepare beds for summer planting. Start seeds indoors. "
            "Good time to plant fruit trees and establish perennials."
        ),
    }
    return notes.get(sub_season, "Check local conditions for planting guidance.")


class ClimateService:
    """Provides climate data via Open-Meteo API with in-memory caching.

    Uses the Open-Meteo forecast API for current conditions and the
    historical archive for monthly averages. Falls back to hardcoded
    Mauritius averages when the API is unreachable.
    """

    def __init__(self):
        self._cache: Dict[str, tuple] = {}  # key -> (timestamp, data)

    def _get_cache(self, key: str):
        """Return cached value if within TTL, else None."""
        entry = self._cache.get(key)
        if entry is None:
            return None
        ts, data = entry
        if time.time() - ts > CACHE_TTL:
            del self._cache[key]
            return None
        return data

    def _set_cache(self, key: str, data):
        """Store data in cache with current timestamp."""
        self._cache[key] = (time.time(), data)

    # ------------------------------------------------------------------
    # Current conditions
    # ------------------------------------------------------------------

    async def fetch_current_climate(self, lat: float, lon: float) -> dict:
        """Fetch current weather conditions from Open-Meteo.

        Returns a dict with temperature_c, humidity_percent, wind_speed_kmh,
        precipitation_mm, season, sub_season, and gardening_notes.
        """
        cache_key = f"current_{lat:.2f}_{lon:.2f}"
        cached = self._get_cache(cache_key)
        if cached:
            return cached

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.get(
                    "https://api.open-meteo.com/v1/forecast",
                    params={
                        "latitude": lat,
                        "longitude": lon,
                        "current_weather": "true",
                    },
                )
                resp.raise_for_status()
                api_data = resp.json()

            cw = api_data.get("current_weather", {})
            temp = cw.get("temperature", 25.0)
            wind = cw.get("windspeed", 10.0)

            # Open-Meteo current_weather doesn't include humidity/precip
            # so we use fallback values for those
            import datetime
            month = datetime.datetime.now().month
            fallback = MAURITIUS_FALLBACK.get(month, MAURITIUS_FALLBACK[1])

            season = get_mauritius_season(month)
            sub = get_sub_season(month)

            result = {
                "temperature_c": temp,
                "humidity_percent": fallback["humidity"],
                "wind_speed_kmh": wind,
                "precipitation_mm": fallback["rainfall"] / 30,  # daily approx
                "season": season,
                "sub_season": sub,
                "gardening_notes": _gardening_notes(season, sub),
            }

            self._set_cache(cache_key, result)
            return result

        except Exception as e:
            logger.warning("Open-Meteo API failed: %s. Using fallback data.", e)
            return self._fallback_current(lat, lon)

    def _fallback_current(self, lat: float, lon: float) -> dict:
        """Return fallback current weather using historical averages."""
        import datetime
        month = datetime.datetime.now().month
        fb = MAURITIUS_FALLBACK.get(month, MAURITIUS_FALLBACK[1])
        season = get_mauritius_season(month)
        sub = get_sub_season(month)

        return {
            "temperature_c": fb["avg_temp"],
            "humidity_percent": fb["humidity"],
            "wind_speed_kmh": 15.0,
            "precipitation_mm": fb["rainfall"] / 30,
            "season": season,
            "sub_season": sub,
            "gardening_notes": _gardening_notes(season, sub),
        }

    # ------------------------------------------------------------------
    # Monthly averages
    # ------------------------------------------------------------------

    async def fetch_monthly_averages(self, lat: float, lon: float) -> List[dict]:
        """Return 12-month average climate data.

        Tries the Open-Meteo historical archive first, falls back to
        hardcoded Mauritius data.
        """
        cache_key = f"monthly_{lat:.2f}_{lon:.2f}"
        cached = self._get_cache(cache_key)
        if cached:
            return cached

        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                resp = await client.get(
                    "https://archive-api.open-meteo.com/v1/archive",
                    params={
                        "latitude": lat,
                        "longitude": lon,
                        "start_date": "2023-01-01",
                        "end_date": "2023-12-31",
                        "monthly": "temperature_2m_mean,temperature_2m_min,temperature_2m_max,precipitation_sum",
                        "timezone": "Indian/Mauritius",
                    },
                )
                resp.raise_for_status()
                api_data = resp.json()

            monthly_data = api_data.get("monthly", {})
            temps_mean = monthly_data.get("temperature_2m_mean", [])
            temps_min = monthly_data.get("temperature_2m_min", [])
            temps_max = monthly_data.get("temperature_2m_max", [])
            precip = monthly_data.get("precipitation_sum", [])

            if len(temps_mean) != 12:
                raise ValueError(f"Expected 12 months, got {len(temps_mean)}")

            result = []
            for i in range(12):
                month = i + 1
                season = get_mauritius_season(month)
                fb = MAURITIUS_FALLBACK[month]
                result.append({
                    "month": month,
                    "month_name": MONTH_NAMES[month],
                    "avg_temp_c": round(temps_mean[i], 1),
                    "min_temp_c": round(temps_min[i], 1),
                    "max_temp_c": round(temps_max[i], 1),
                    "avg_rainfall_mm": round(precip[i], 1),
                    "avg_humidity_percent": fb["humidity"],
                    "season": season,
                    "is_planting_season": month in (3, 4, 5, 9, 10, 11),
                })

            self._set_cache(cache_key, result)
            return result

        except Exception as e:
            logger.warning("Open-Meteo archive API failed: %s. Using fallback.", e)
            return self._fallback_monthly()

    def _fallback_monthly(self) -> List[dict]:
        """Return fallback monthly averages from hardcoded Mauritius data."""
        result = []
        for month in range(1, 13):
            fb = MAURITIUS_FALLBACK[month]
            season = get_mauritius_season(month)
            result.append({
                "month": month,
                "month_name": MONTH_NAMES[month],
                "avg_temp_c": fb["avg_temp"],
                "min_temp_c": fb["min_temp"],
                "max_temp_c": fb["max_temp"],
                "avg_rainfall_mm": fb["rainfall"],
                "avg_humidity_percent": fb["humidity"],
                "season": season,
                "is_planting_season": month in (3, 4, 5, 9, 10, 11),
            })
        return result
