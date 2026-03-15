"""Plant catalog and recommendation endpoints."""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from app.api.deps import get_current_user
from app.config import settings
from app.models.plant_models import (
    Plant,
    RecommendRequest,
    RecommendResponse,
)
from app.services.gemini_recommender import GeminiRecommender
from app.services.ollama_recommender import OllamaRecommender
from app.services.perenual_service import PerenualService
from app.services.plant_recommender import PlantRecommender

logger = logging.getLogger("gardnx")
router = APIRouter()

# Singletons — initialised once at first request
_recommender: PlantRecommender | None = None
_perenual: PerenualService | None = None
_gemini: GeminiRecommender | None = None
_ollama: OllamaRecommender | None = None


def _get_recommender() -> PlantRecommender:
    global _recommender
    if _recommender is None:
        _recommender = PlantRecommender()
    return _recommender


def _get_perenual() -> PerenualService:
    global _perenual
    if _perenual is None:
        _perenual = PerenualService(api_key=settings.perenual_api_key)
    return _perenual


def _get_gemini() -> GeminiRecommender:
    global _gemini
    if _gemini is None:
        _gemini = GeminiRecommender(api_key=settings.gemini_api_key)
    return _gemini


def _get_ollama() -> OllamaRecommender:
    global _ollama
    if _ollama is None:
        _ollama = OllamaRecommender(model="gemma3:1b")
    return _ollama


@router.get("/search")
async def search_plants_global(
    q: str = Query(..., min_length=2, description="Search term"),
    page: int = Query(1, ge=1, description="Perenual page number"),
    user_id: str = Depends(get_current_user),
):
    """Search the global Perenual plant database.

    Returns Flutter-compatible plant JSON objects tagged with
    ``"perenual"`` in their ``tags`` list so the client can
    distinguish them from curated Mauritius plants.

    Results are cached 24 h on the backend — safe to call on
    every search keystroke after debouncing.
    """
    perenual = _get_perenual()
    results = await perenual.search_catalog(query=q, page=page)
    logger.info("Global search '%s' p%d → %d results", q, page, len(results))
    return results


@router.get("/catalog", response_model=list[Plant])
async def get_catalog(
    type: Optional[str] = Query(None, description="Filter by plant type (vegetable, herb, fruit, flower)"),
    sun: Optional[str] = Query(None, description="Filter by sun requirement (full_sun, partial_shade, full_shade)"),
    season: Optional[int] = Query(None, ge=1, le=12, description="Filter by sowing month (1-12)"),
    region: Optional[str] = Query(None, description="Filter by Mauritius region"),
    search: Optional[str] = Query(None, description="Search term for plant name"),
    enrich: bool = Query(False, description="Enrich results with Perenual images (uses API quota)"),
    user_id: str = Depends(get_current_user),
):
    """Return the full plant catalog, optionally filtered and Perenual-enriched.

    Pass ?enrich=true to fetch plant images from the Perenual API.
    Images are cached for 24 hours so repeated calls don't burn quota.
    """
    recommender = _get_recommender()
    plants = list(recommender.plants.values())

    if type:
        plants = [p for p in plants if p.type == type]
    if sun:
        plants = [p for p in plants if p.conditions.sunlight == sun]
    if season:
        plants = [p for p in plants if season in p.timing.sowing_months]
    if region:
        plants = [p for p in plants if region in p.mauritius_regions]
    if search:
        term = search.lower()
        plants = [
            p for p in plants
            if term in p.name.lower()
            or term in p.name_fr.lower()
            or term in p.scientific_name.lower()
            or term in p.description.lower()
        ]

    if enrich:
        perenual = _get_perenual()
        plants = await perenual.enrich_plants(plants, max_lookups=10)

    logger.info(
        "Catalog: %d results (type=%s sun=%s season=%s region=%s search=%s enrich=%s)",
        len(plants), type, sun, season, region, search, enrich,
    )
    return plants


@router.get("/engine-status")
async def get_engine_status(user_id: str = Depends(get_current_user)):
    """Return availability status of each recommendation engine."""
    gemini = _get_gemini()
    ollama = _get_ollama()

    statuses = {}

    # Check Gemini
    if not settings.gemini_api_key:
        statuses["gemini"] = {"available": False, "reason": "No Gemini API key configured"}
    else:
        try:
            import google.generativeai as genai
            genai.configure(api_key=settings.gemini_api_key)
            statuses["gemini"] = {"available": True, "reason": "Gemini 2.0 Flash Lite (cloud AI)"}
        except Exception as e:
            statuses["gemini"] = {"available": False, "reason": f"Gemini error: {str(e)[:80]}"}

    # Check Ollama
    try:
        import httpx
        async with httpx.AsyncClient(timeout=3.0) as client:
            resp = await client.get("http://localhost:11434/api/tags")
            if resp.status_code == 200:
                models = resp.json().get("models", [])
                model_names = [m.get("name", "") for m in models]
                has_gemma = any("gemma" in n for n in model_names)
                if has_gemma:
                    statuses["ollama"] = {"available": True, "reason": "Gemma via Ollama (local AI, offline)"}
                else:
                    statuses["ollama"] = {"available": False, "reason": "Ollama running but gemma model not installed. Run: ollama pull gemma3:1b"}
            else:
                statuses["ollama"] = {"available": False, "reason": "Ollama server not responding"}
    except Exception:
        statuses["ollama"] = {"available": False, "reason": "Ollama not running. Install from ollama.ai and run: ollama serve"}

    statuses["rules"] = {"available": True, "reason": "Built-in rules (always available, works offline)"}
    return statuses


@router.get("/{plant_id}", response_model=Plant)
async def get_plant(
    plant_id: str,
    enrich: bool = Query(False, description="Enrich with Perenual image"),
    user_id: str = Depends(get_current_user),
):
    """Return a single plant by its ID, optionally Perenual-enriched."""
    recommender = _get_recommender()
    plant = recommender.plants.get(plant_id)
    if plant is None:
        raise HTTPException(status_code=404, detail=f"Plant '{plant_id}' not found")

    if enrich and plant.image_url is None:
        perenual = _get_perenual()
        data = await perenual.search_plant(
            name=plant.name,
            scientific_name=plant.scientific_name,
        )
        if data and data.get("image_url"):
            plant = plant.model_copy(update={
                "image_url": data["image_url"],
                "perenual_id": data.get("perenual_id"),
            })

    return plant


@router.post("/recommend", response_model=RecommendResponse)
async def recommend_plants(
    body: RecommendRequest,
    user_id: str = Depends(get_current_user),
):
    """Generate scored plant recommendations, enriched with Perenual images.

    Engine priority:
      1. Gemini 2.0 Flash Lite (cloud — free tier, needs internet)
      2. Ollama (local LLM — free, offline, no quota)
      3. Rule-based weighted algorithm (always works)
    Results are then enriched with Perenual plant images.
    """
    recommender = _get_recommender()
    ollama = _get_ollama()
    gemini = _get_gemini()

    preferred = getattr(body, 'preferred_engine', None)

    # Build ordered engine list based on preference
    # Default priority: gemini → ollama → rules
    if preferred == "ollama":
        engine_order = [("ollama", ollama), ("gemini", gemini), ("rules", None)]
    elif preferred == "rules":
        engine_order = [("rules", None)]
    else:  # gemini or None (default)
        engine_order = [("gemini", gemini), ("ollama", ollama), ("rules", None)]

    result = None
    engine = "rules"
    for eng_name, eng in engine_order:
        if eng_name == "rules":
            result = recommender.recommend(body)
            engine = "rules"
            break
        attempt = await eng.recommend(body, recommender.plants)
        if attempt is not None:
            result = attempt
            engine = eng_name
            break

    if result is None:
        result = recommender.recommend(body)
        engine = "rules"

    # --- Enrich with Perenual images -----------------------------------------
    perenual = _get_perenual()
    enriched_plants = await perenual.enrich_plants(
        [r.plant for r in result.recommendations],
        max_lookups=10,
    )
    result.recommendations = [
        rec.model_copy(update={"plant": enriched_plants[i]})
        for i, rec in enumerate(result.recommendations)
    ]

    logger.info(
        "Recommend [%s]: %d results for month=%d sun=%s region=%s",
        engine, result.total, body.month, body.bed_sunlight, body.region,
    )
    result.engine_used = engine
    return result


