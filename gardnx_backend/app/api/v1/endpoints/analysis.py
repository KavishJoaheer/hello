"""Garden photo analysis endpoints: upload, segment, and retrieve results."""

import uuid
import logging
from typing import Dict

from fastapi import APIRouter, Depends, UploadFile, File, HTTPException

from app.api.deps import get_current_user, get_analyzer
from app.models.analysis_models import (
    PhotoUploadResponse,
    SegmentationRequest,
    SegmentationResponse,
)
from app.utils.image_utils import get_image_dimensions, compress_image
from app.services.garden_analyzer import GardenAnalyzer

logger = logging.getLogger("gardnx")
router = APIRouter()

# In-memory storage for uploaded images and analysis results
_photo_store: Dict[str, bytes] = {}
_result_store: Dict[str, SegmentationResponse] = {}


@router.post("/upload", response_model=PhotoUploadResponse)
async def upload_photo(
    file: UploadFile = File(...),
    user_id: str = Depends(get_current_user),
):
    """Upload a garden photo for analysis.

    Accepts an image file, generates a unique photo_id, compresses
    the image, stores it in memory, and returns metadata.
    """
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    image_bytes = await file.read()
    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty file")

    # Compress large images
    compressed = compress_image(image_bytes, max_size=1920, quality=85)
    width, height = get_image_dimensions(compressed)

    photo_id = str(uuid.uuid4())
    _photo_store[photo_id] = compressed

    logger.info(
        "Photo uploaded: id=%s user=%s size=%dx%d bytes=%d",
        photo_id, user_id, width, height, len(compressed),
    )

    return PhotoUploadResponse(
        id=photo_id,
        imageUrl=f"/api/v1/analysis/photo/{photo_id}",
        width=width,
        height=height,
    )


@router.post("/segment/{photo_id}", response_model=SegmentationResponse)
async def segment_photo(
    photo_id: str,
    body: SegmentationRequest | None = None,
    user_id: str = Depends(get_current_user),
    analyzer: GardenAnalyzer = Depends(get_analyzer),
):
    """Run segmentation on a previously uploaded photo.

    Accepts an optional SegmentationRequest body to specify a
    selected area. Returns detected zones with confidence scores.
    """
    image_bytes = _photo_store.get(photo_id)
    if image_bytes is None:
        raise HTTPException(status_code=404, detail=f"Photo {photo_id} not found")

    selected_area = body.selected_area if body else None

    result = analyzer.analyze(image_bytes, selected_area=selected_area)

    # Cache result
    _result_store[photo_id] = result

    logger.info(
        "Segmentation complete: photo=%s zones=%d time=%dms",
        photo_id, len(result.zones), result.processing_time_ms,
    )

    return result


@router.get("/result/{photo_id}", response_model=SegmentationResponse)
async def get_result(
    photo_id: str,
    user_id: str = Depends(get_current_user),
):
    """Retrieve cached segmentation result for a photo."""
    result = _result_store.get(photo_id)
    if result is None:
        raise HTTPException(
            status_code=404,
            detail=f"No analysis result found for photo {photo_id}. Run /segment first.",
        )
    return result
