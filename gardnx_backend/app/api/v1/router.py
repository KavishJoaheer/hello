"""API v1 router aggregating all endpoint modules."""

from fastapi import APIRouter

from app.api.v1.endpoints import analysis, plants, layout, climate, calendar

v1_router = APIRouter()

v1_router.include_router(analysis.router, prefix="/analysis", tags=["Analysis"])
v1_router.include_router(plants.router, prefix="/plants", tags=["Plants"])
v1_router.include_router(layout.router, prefix="/layout", tags=["Layout"])
v1_router.include_router(climate.router, prefix="/climate", tags=["Climate"])
v1_router.include_router(calendar.router, prefix="/calendar", tags=["Calendar"])
