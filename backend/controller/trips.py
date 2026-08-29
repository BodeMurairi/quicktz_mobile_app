from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from data.database import get_db
from schemas.trip import TripResponse, TripCreate, TripUpdate
from services.trip_service import (
    search_trips, get_trip, create_trip, list_upcoming_trips, list_trips, update_trip,
)
from middleware.auth import get_current_agency, require_owns_agency
from models.agency import Agency
from models.route import Route

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
    # Public browse (mobile home screen, or filtered by route/status/date with no
    # agency_id). The agency dashboard's "every trip for my agency" view moved to
    # GET /agencies/{agency_id}/trips, which requires that agency's own login.
    if agency_id:
        raise HTTPException(status_code=401, detail="Use GET /agencies/{agency_id}/trips (with an agency login) instead")
    if route_id or status or from_date or to_date:
        return await list_trips(db, None, route_id, status, from_date, to_date)
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
async def create_new_trip(
    data: TripCreate,
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    route = await db.get(Route, data.route_id)
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    require_owns_agency(current_agency, route.agency_id)
    return await create_trip(db, data)


@router.patch("/{trip_id}", response_model=TripResponse)
async def update_existing_trip(
    trip_id: str,
    data: TripUpdate,
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    trip = await get_trip(db, trip_id)
    require_owns_agency(current_agency, trip.route.agency_id)
    return await update_trip(db, trip_id, data)
