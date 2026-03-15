"""Garden layout generation and validation endpoints."""

import logging

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.models.layout_models import (
    LayoutRequest,
    LayoutResponse,
    ValidationRequest,
    ValidationResponse,
    SpacingRequest,
    SpacingResponse,
    RecommendBedRequest,
    RecommendBedResponse,
    BedSuggestion,
)
from app.config import settings
from app.services.layout_generator import LayoutGenerator
from app.services.companion_checker import CompanionChecker
from app.services.gemini_companion_checker import GeminiCompanionChecker
from app.services.plant_recommender import PlantRecommender
from app.services.spacing_calculator import calculate_max_plants

logger = logging.getLogger("gardnx")
router = APIRouter()

# Singleton instances
_layout_gen: LayoutGenerator | None = None
_companion: CompanionChecker | None = None
_gemini_companion: GeminiCompanionChecker | None = None
_plant_rec: PlantRecommender | None = None


def _get_layout_generator() -> LayoutGenerator:
    global _layout_gen
    if _layout_gen is None:
        _layout_gen = LayoutGenerator()
    return _layout_gen


def _get_companion_checker() -> CompanionChecker:
    global _companion
    if _companion is None:
        _companion = CompanionChecker()
    return _companion


def _get_gemini_companion_checker() -> GeminiCompanionChecker:
    global _gemini_companion
    if _gemini_companion is None:
        _gemini_companion = GeminiCompanionChecker(api_key=settings.gemini_api_key)
    return _gemini_companion


def _get_plant_recommender() -> PlantRecommender:
    global _plant_rec
    if _plant_rec is None:
        _plant_rec = PlantRecommender()
    return _plant_rec


@router.post("/generate", response_model=LayoutResponse)
async def generate_layout(
    body: LayoutRequest,
    user_id: str = Depends(get_current_user),
):
    """Generate an optimised garden bed layout.

    Accepts bed dimensions and a list of selected plants with quantities.
    Returns a grid-based layout with placements, utilisation statistics,
    and companion-planting warnings.
    """
    generator = _get_layout_generator()
    result = generator.generate(body)

    logger.info(
        "Layout generated: %d placements, %.1f%% utilisation, %d warnings",
        len(result.placements),
        result.statistics.utilization_percent,
        len(result.warnings),
    )
    return result


@router.post("/validate", response_model=ValidationResponse)
async def validate_layout(
    body: ValidationRequest,
    user_id: str = Depends(get_current_user),
):
    """Validate an existing layout for companion-planting conflicts.

    Checks every placed plant against its neighbours (including diagonals)
    and returns any warnings or errors.
    """
    # Try AI companion check first; fall back to static rules if offline/unavailable
    gemini = _get_gemini_companion_checker()
    warnings = gemini.check_layout(
        placements=body.placements,
        bed_width_cm=body.bed.width_cm,
        bed_height_cm=body.bed.height_cm,
    )
    if warnings is None:
        logger.info("Validate: Gemini unavailable, using static companion rules")
        checker = _get_companion_checker()
        warnings = checker.check_layout(
            placements=body.placements,
            bed_width_cm=body.bed.width_cm,
            bed_height_cm=body.bed.height_cm,
        )

    errors = [w for w in warnings if w.severity == "error"]

    logger.info("Validation: %d warnings, %d errors", len(warnings), len(errors))

    return ValidationResponse(
        is_valid=len(errors) == 0,
        warnings=warnings,
        total_warnings=len(warnings),
        total_errors=len(errors),
    )


@router.post("/spacing", response_model=SpacingResponse)
async def calculate_spacing(
    body: SpacingRequest,
    user_id: str = Depends(get_current_user),
):
    """Calculate the maximum number of plants that fit in a bed.

    Given bed dimensions and plant spacing requirements, returns
    the grid layout (rows x cols) and actual spacing values.
    """
    result = calculate_max_plants(
        bed_width_cm=body.bed_width_cm,
        bed_height_cm=body.bed_height_cm,
        spacing_between_cm=body.between_plants_cm,
        spacing_rows_cm=body.between_rows_cm,
    )

    total_area = body.bed_width_cm * body.bed_height_cm
    used_area = result["max_count"] * body.between_plants_cm * body.between_rows_cm
    utilisation = min(100.0, (used_area / total_area) * 100) if total_area > 0 else 0

    return SpacingResponse(
        max_plants=result["max_count"],
        rows=result["rows"],
        cols=result["cols"],
        actual_between_plants_cm=result["cell_width_cm"],
        actual_between_rows_cm=result["cell_height_cm"],
        bed_utilization_percent=round(utilisation, 1),
    )


# Season name → list of sowing months
_SEASON_MONTHS: dict[str, list[int]] = {
    "summer": [11, 12, 1, 2, 3],
    "winter": [5, 6, 7, 8, 9],
    "autumn": [3, 4, 5],
    "spring": [9, 10, 11],
}


@router.post("/recommend", response_model=RecommendBedResponse)
async def recommend_plants_for_bed(
    body: RecommendBedRequest,
    user_id: str = Depends(get_current_user),
):
    """Recommend suitable plants for a garden bed.

    Scores plants from the Mauritius catalog based on bed sun exposure,
    current season, soil type, and region, then returns the top 15.
    """
    rec = _get_plant_recommender()
    season_months = _SEASON_MONTHS.get(body.season.lower(), list(range(1, 13)))
    bed_area = body.width_cm * body.height_cm

    suggestions: list[BedSuggestion] = []
    for plant in rec.plants.values():
        score = 0.75  # base score for all Mauritius-curated plants
        reasons: list[str] = []

        # Sun exposure match
        if plant.conditions.sunlight == body.sun_exposure:
            score = min(score + 0.10, 1.0)
            reasons.append(f"Suits {body.sun_exposure.replace('_', ' ')}")

        # Season match
        if any(m in plant.timing.sowing_months for m in season_months):
            score = min(score + 0.10, 1.0)
            reasons.append("Good planting season")

        # Region match
        if body.region in plant.mauritius_regions:
            score = min(score + 0.05, 1.0)
            reasons.append(f"Grows well in {body.region}")

        if score < 0.35:
            continue

        spacing = plant.spacing.between_plants_cm * plant.spacing.between_rows_cm
        max_count = max(1, min(20, int(bed_area / max(spacing, 900))))

        # Companion names
        companion_names = [
            rec.plants[cid].name
            for cid in plant.companion_plants[:3]
            if cid in rec.plants
        ]

        suggestions.append(BedSuggestion(
            plant_id=plant.id,
            plant_name=plant.name,
            suitability_score=round(score, 2),
            reasons=reasons if reasons else ["Suitable for Mauritius climate"],
            companion_names=companion_names,
            max_count=max_count,
        ))

    suggestions.sort(key=lambda s: s.suitability_score, reverse=True)
    logger.info(
        "Bed recommendations: %d results (sun=%s season=%s region=%s)",
        len(suggestions[:15]), body.sun_exposure, body.season, body.region,
    )
    return RecommendBedResponse(recommendations=suggestions[:15])
