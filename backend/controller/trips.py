from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from data.database import get_db
from schemas.trip import TripResponse, TripCreate, TripUpdate
from services.trip_service import (
    search_trips, get_trip, create_trip, list_upcoming_trips, list_trips, update_trip,
)

router = APIRouter()


@router.get("", response_model=List[TripResponse])
async def get_trips(
    agency_id: Optional[str] = Query(None),
    route_id: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    from_date: Optional[str] = Query(None),
    to_date: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
):
    # Agency dashboard: full trip list for that agency, any status.
    if agency_id or route_id or status or from_date or to_date:
        return await list_trips(db, agency_id, route_id, status, from_date, to_date)
    # Public / mobile home screen: next scheduled departures, system-wide.
    return await list_upcoming_trips(db)


@router.get("/search", response_model=List[TripResponse])
async def search(
    origin: str = Query(...),
    destination: str = Query(...),
    departure_date: str = Query(..., description="YYYY-MM-DD"),
    passengers: int = Query(1, ge=1),
    db: AsyncSession = Depends(get_db),
):
    return await search_trips(db, origin, destination, departure_date, passengers)


@router.get("/{trip_id}", response_model=TripResponse)
async def get_trip_detail(trip_id: str, db: AsyncSession = Depends(get_db)):
    return await get_trip(db, trip_id)


@router.post("", response_model=TripResponse, status_code=201)
async def create_new_trip(data: TripCreate, db: AsyncSession = Depends(get_db)):
    return await create_trip(db, data)


@router.patch("/{trip_id}", response_model=TripResponse)
async def update_existing_trip(trip_id: str, data: TripUpdate, db: AsyncSession = Depends(get_db)):
    return await update_trip(db, trip_id, data)
