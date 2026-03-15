"""Mauritius season and climate utilities."""


def get_mauritius_season(month: int) -> str:
    """
    Returns main season for Mauritius.
    Summer (hot/humid): November - April
    Winter (cool/dry): May - October
    """
    if month in [11, 12, 1, 2, 3, 4]:
        return "summer"
    return "winter"


def get_sub_season(month: int) -> str:
    """Returns detailed sub-season label."""
    if month in [1, 2, 3]:
        return "summer_rainy"    # Cyclone risk, heavy rain
    elif month in [4, 5]:
        return "autumn_transition"
    elif month in [6, 7, 8]:
        return "winter_dry"
    elif month in [9, 10]:
        return "spring_transition"
    else:  # 11, 12
        return "summer_early"


def is_cyclone_season(month: int) -> bool:
    """Mauritius cyclone season: January to March."""
    return month in [1, 2, 3]


def get_planting_advice(month: int) -> str:
    """Return general planting advice for the month."""
    season = get_sub_season(month)
    advice_map = {
        "summer_rainy": "Cyclone season — focus on hardy crops, ensure drainage. Good for tropical fruits.",
        "autumn_transition": "Excellent planting time — temperatures cooling, good for vegetables.",
        "winter_dry": "Ideal for vegetables and herbs. Minimal pest pressure. Irrigate regularly.",
        "spring_transition": "Good for starting warm-season crops. Temperatures rising.",
        "summer_early": "Plant heat-tolerant varieties. Early morning watering recommended.",
    }
    return advice_map.get(season, "Good conditions for gardening.")
