import uuid
from typing import List
from datetime import datetime, date
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import joinedload, selectinload
from fastapi import HTTPException

from models.trip import Trip
from models.route import Route
from schemas.trip import TripCreate


async def search_trips(db: AsyncSession, origin: str, destination: str,
                       departure_date: str, passengers: int = 1) -> List[Trip]:
    try:
        search_date = date.fromisoformat(departure_date)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")

    result = await db.execute(
        select(Trip)
        .join(Route, Trip.route_id == Route.id)
        .where(
            Route.origin.ilike(f"%{origin}%"),
            Route.destination.ilike(f"%{destination}%"),
            Trip.status == "scheduled",
            Trip.available_seats >= passengers,
            Trip.is_active == True,
        )
        .options(selectinload(Trip.route).selectinload(Route.agency))
    )
    trips = list(result.scalars().all())
    return [t for t in trips if t.departure_datetime.date() == search_date]


async def get_trip(db: AsyncSession, trip_id: str) -> Trip:
    result = await db.execute(
        select(Trip)
        .where(Trip.id == trip_id)
        .options(selectinload(Trip.route).selectinload(Route.agency))
    )
    trip = result.scalar_one_or_none()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    return trip


async def create_trip(db: AsyncSession, data: TripCreate) -> Trip:
    trip = Trip(id=str(uuid.uuid4()), available_seats=data.total_seats, **data.model_dump())
    db.add(trip)
    await db.commit()
    await db.refresh(trip)
    return trip


async def list_upcoming_trips(db: AsyncSession, limit: int = 10) -> List[Trip]:
    result = await db.execute(
        select(Trip)
        .where(Trip.departure_datetime >= datetime.utcnow(), Trip.status == "scheduled")
        .options(selectinload(Trip.route).selectinload(Route.agency))
        .order_by(Trip.departure_datetime)
        .limit(limit)
    )
    return list(result.scalars().all())
