"""Garden calendar and task generation endpoints."""

import logging
from datetime import date
from typing import List, Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.api.deps import get_current_user
from app.services.calendar_service import CalendarService

logger = logging.getLogger("gardnx")
router = APIRouter()


# --- Request / Response models ---

class PlantCalendarEntry(BaseModel):
    """A plant and its placement info for calendar generation."""
    plant_id: str
    plant_name: str
    bed_name: str = "Bed A"
    sowing_months: List[int] = Field(default_factory=list)
    transplant_months: List[int] = Field(default_factory=list)
    harvest_months: List[int] = Field(default_factory=list)
    days_to_germination: int = 7
    days_to_harvest: int = 60


class GardenInfo(BaseModel):
    """Metadata about the garden for calendar context."""
    region: str = "north"
    latitude: float = -20.2
    longitude: float = 57.5


class CalendarGenerateRequest(BaseModel):
    """Request to generate a planting calendar."""
    plants: List[PlantCalendarEntry]
    garden_info: GardenInfo = Field(default_factory=GardenInfo)
    start_date: Optional[str] = None  # ISO format YYYY-MM-DD


class CalendarEvent(BaseModel):
    """A single calendar event."""
    plant_id: str
    plant_name: str
    event_type: str  # sow, transplant, harvest, water, fertilize
    start_date: str
    end_date: Optional[str] = None
    bed_name: str = ""
    description: str = ""
    priority: str = "normal"  # low, normal, high


class CalendarResponse(BaseModel):
    """Response with generated calendar events."""
    events: List[CalendarEvent]
    total_events: int
    date_range_start: str
    date_range_end: str


class TaskGenerateRequest(BaseModel):
    """Request to convert calendar events to tasks."""
    events: List[CalendarEvent]
    current_date: Optional[str] = None


class TaskResponse(BaseModel):
    """Response with human-readable task strings."""
    tasks: List[str]
    urgent_tasks: List[str]
    upcoming_tasks: List[str]


# --- Endpoints ---

@router.post("/generate", response_model=CalendarResponse)
async def generate_calendar(
    body: CalendarGenerateRequest,
    user_id: str = Depends(get_current_user),
):
    """Generate a planting calendar based on plant selections.

    Creates sow, transplant, and harvest events with calculated dates
    based on each plant's timing data and the current date.
    """
    service = CalendarService()

    start = date.fromisoformat(body.start_date) if body.start_date else date.today()

    events = service.generate_calendar(
        plants=body.plants,
        start_date=start,
    )

    date_strs = [e.start_date for e in events]
    if body.start_date:
        date_strs.append(body.start_date)

    min_date = min(date_strs) if date_strs else start.isoformat()
    max_date = max(date_strs) if date_strs else start.isoformat()

    logger.info("Calendar generated: %d events from %s to %s",
                len(events), min_date, max_date)

    return CalendarResponse(
        events=events,
        total_events=len(events),
        date_range_start=min_date,
        date_range_end=max_date,
    )


@router.post("/tasks", response_model=TaskResponse)
async def generate_tasks(
    body: TaskGenerateRequest,
    user_id: str = Depends(get_current_user),
):
    """Convert calendar events into human-readable task strings.

    Categorises tasks as urgent (within 7 days), upcoming (within 30 days),
    or later. Returns both the full list and the filtered urgent/upcoming lists.
    """
    service = CalendarService()

    current = date.fromisoformat(body.current_date) if body.current_date else date.today()

    tasks, urgent, upcoming = service.generate_tasks(
        events=body.events,
        current_date=current,
    )

    logger.info("Tasks generated: %d total, %d urgent, %d upcoming",
                len(tasks), len(urgent), len(upcoming))

    return TaskResponse(
        tasks=tasks,
        urgent_tasks=urgent,
        upcoming_tasks=upcoming,
    )
