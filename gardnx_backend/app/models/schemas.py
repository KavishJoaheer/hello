"""Core Pydantic models for API requests and responses."""

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    """Health check response."""

    status: str = "ok"
    model_loaded: bool = False
    mock_mode: bool = True


class Point(BaseModel):
    """A 2D point with normalized coordinates (0-1)."""

    x: float = Field(..., ge=0.0, le=1.0, description="Normalized x coordinate")
    y: float = Field(..., ge=0.0, le=1.0, description="Normalized y coordinate")


class Zone(BaseModel):
    """A detected zone in the garden image."""

    zone_id: str = Field(..., description="Unique zone identifier")
    zone_type: str = Field(
        ..., description="Type of zone: soil, lawn, path, shade, existing_plant"
    )
    polygon: list[Point] = Field(..., description="Polygon boundary as list of points")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Detection confidence")
    area_fraction: float = Field(
        ..., ge=0.0, le=1.0, description="Fraction of total image area"
    )
    center: Point = Field(..., description="Center point of the zone")


class PhotoUploadResponse(BaseModel):
    """Response after uploading a garden photo."""

    photo_id: str = Field(..., description="Unique identifier for the uploaded photo")
    url: str = Field(..., description="URL to access the uploaded photo")
    message: str = "Photo uploaded successfully"


class SegmentationRequest(BaseModel):
    """Request to run segmentation on a photo."""

    resolution: str = Field(
        default="medium",
        description="Processing resolution: low, medium, high",
    )


class SegmentationResponse(BaseModel):
    """Response containing segmentation results."""

    photo_id: str
    zones: list[Zone]
    total_zones: int
    processing_time_ms: float
    mock_mode: bool = False
    image_width: int = 0
    image_height: int = 0
