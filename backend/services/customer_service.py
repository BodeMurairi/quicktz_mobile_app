from datetime import datetime
from typing import List, Dict
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from models.booking import Booking
from models.trip import Trip
from models.route import Route
from schemas.customer import CustomerResponse


async def list_agency_customers(db: AsyncSession, agency_id: str) -> List[CustomerResponse]:
    result = await db.execute(
        select(Booking)
        .join(Trip, Booking.trip_id == Trip.id)
        .join(Route, Trip.route_id == Route.id)
        .where(Route.agency_id == agency_id, Booking.status != "cancelled")
        .options(
            selectinload(Booking.trip).selectinload(Trip.route),
            selectinload(Booking.user),
        )
    )
    bookings = list(result.scalars().unique().all())

    groups: Dict[str, List[Booking]] = {}
    for b in bookings:
        key = b.passenger_phone or f"name:{b.passenger_name.strip().lower()}"
        groups.setdefault(key, []).append(b)

    customers: List[CustomerResponse] = []
    for key, group in groups.items():
        group.sort(key=lambda b: b.created_at, reverse=True)
        latest = group[0]
        total_spent = sum(b.total_price for b in group)
        travel_dates = [b.trip.departure_datetime for b in group if b.trip]
        last_travel = max(travel_dates) if travel_dates else None

        # Enrich with the real account's email/premium status, but only when that
        # account's own phone number matches the passenger phone typed in for these
        # bookings — this naturally picks up rider-app bookings (accurate) while
        # skipping agency manual bookings (whose user_id is the staff member, not
        # the walk-in customer).
        email = None
        is_premium = False
        user_id = None
        for b in group:
            if b.user and latest.passenger_phone and b.user.phone_number == latest.passenger_phone:
                email = b.user.email
                is_premium = b.user.is_premium
                user_id = b.user.id
                break

        customers.append(CustomerResponse(
            id=user_id or key,
            user_id=user_id,
            full_name=latest.passenger_name,
            email=email,
            phone_number=latest.passenger_phone,
            booking_count=len(group),
            total_spent=total_spent,
            last_travel=last_travel,
            is_premium=is_premium,
        ))

    customers.sort(key=lambda c: c.last_travel or datetime.min, reverse=True)
    return customers
