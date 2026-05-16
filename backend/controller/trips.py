from typing import List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from data.database import get_db
from schemas.trip import TripResponse, TripCreate
from services.trip_service import search_trips, get_trip, create_trip, list_upcoming_trips

router = APIRouter()


@router.get("", response_model=List[TripResponse])
async def get_upcoming(db: AsyncSession = Depends(get_db)):
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
