import uuid
from typing import List, Optional
from datetime import datetime, date
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import joinedload, selectinload
from fastapi import HTTPException

from models.trip import Trip
from models.route import Route
from schemas.trip import TripCreate, TripUpdate


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
    # Re-fetch with route/agency eagerly loaded — TripResponse nests them, and a bare
    # refresh() leaves those relationships unloaded, which crashes serialization under asyncio.
    return await get_trip(db, trip.id)


async def update_trip(db: AsyncSession, trip_id: str, data: TripUpdate) -> Trip:
    trip = await get_trip(db, trip_id)
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(trip, field, value)
    await db.commit()
    # Re-fetch with route/agency eagerly loaded, same reason as create_trip.
    return await get_trip(db, trip_id)


async def list_upcoming_trips(db: AsyncSession, limit: int = 10) -> List[Trip]:
    """Public feed (mobile home screen): next scheduled departures, system-wide."""
    result = await db.execute(
        select(Trip)
        .where(Trip.departure_datetime >= datetime.utcnow(), Trip.status == "scheduled")
        .options(selectinload(Trip.route).selectinload(Route.agency))
        .order_by(Trip.departure_datetime)
        .limit(limit)
    )
    return list(result.scalars().all())


async def list_trips(
    db: AsyncSession,
    agency_id: Optional[str] = None,
    route_id: Optional[str] = None,
    status: Optional[str] = None,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
) -> List[Trip]:
    """Agency dashboard feed: every trip for the agency, any status, no small cap."""
    query = select(Trip).options(selectinload(Trip.route).selectinload(Route.agency))

    if agency_id:
        query = query.join(Route, Trip.route_id == Route.id).where(Route.agency_id == agency_id)
    if route_id:
        query = query.where(Trip.route_id == route_id)
    if status:
        query = query.where(Trip.status == status)
    if from_date:
        query = query.where(Trip.departure_datetime >= datetime.fromisoformat(from_date))
    if to_date:
        query = query.where(Trip.departure_datetime <= datetime.fromisoformat(to_date))

    # Safety cap: seed/test data can accumulate thousands of rows per agency, which
    # would otherwise ship an unbounded, unpaginated payload to the dashboard table.
    query = query.order_by(Trip.departure_datetime).limit(500)
    result = await db.execute(query)
    return list(result.scalars().all())
