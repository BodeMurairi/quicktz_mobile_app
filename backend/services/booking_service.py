import uuid
import random
import string
import json
from datetime import datetime
from typing import List, Optional, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from fastapi import HTTPException

from models.booking import Booking
from models.ticket import Ticket
from models.payment import Payment
from models.trip import Trip
from models.route import Route
from models.user import User
from schemas.booking import BookingCreate

# Every response that nests `trip` (-> route -> agency), `payment`, and `ticket` needs
# this full chain eagerly loaded, or serialization crashes under async (lazy-load
# outside a greenlet). Reused everywhere a Booking is returned as BookingResponse.
_BOOKING_OPTIONS = (
    selectinload(Booking.trip).selectinload(Trip.route).selectinload(Route.agency),
    selectinload(Booking.payment),
    selectinload(Booking.ticket),
)


def _generate_ticket_code() -> str:
    return "QTZ-" + "".join(random.choices(string.ascii_uppercase + string.digits, k=8))


async def _refetch_booking(db: AsyncSession, booking_id: str) -> Booking:
    result = await db.execute(
        select(Booking).where(Booking.id == booking_id).options(*_BOOKING_OPTIONS)
    )
    booking = result.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking


async def create_booking(db: AsyncSession, user_id: str, data: BookingCreate) -> Booking:
    result = await db.execute(select(Trip).where(Trip.id == data.trip_id))
    trip = result.scalar_one_or_none()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    if trip.available_seats < 1:
        raise HTTPException(status_code=400, detail="No seats available")

    booking = Booking(
        id=str(uuid.uuid4()),
        user_id=user_id,
        trip_id=data.trip_id,
        seat_number=data.seat_number,
        passenger_name=data.passenger_name,
        passenger_phone=data.passenger_phone,
        total_price=trip.price,
        status="confirmed",
    )
    db.add(booking)

    ticket_code = _generate_ticket_code()
    qr_data = json.dumps({
        "code": ticket_code,
        "trip": data.trip_id,
        "passenger": data.passenger_name,
    })
    ticket = Ticket(
        id=str(uuid.uuid4()),
        booking_id=booking.id,
        ticket_code=ticket_code,
        qr_data=qr_data,
        status="active",
    )
    db.add(ticket)

    payment = Payment(
        id=str(uuid.uuid4()),
        booking_id=booking.id,
        amount=trip.price,
        payment_method=data.payment_method,
        status="completed",
        paid_at=datetime.utcnow(),
    )
    db.add(payment)

    trip.available_seats -= 1
    await db.commit()
    return await _refetch_booking(db, booking.id)


async def instant_booking(db: AsyncSession, user: User, trip_id: str) -> Booking:
    """Simulate a booking — fills passenger info from the user's profile."""
    result = await db.execute(select(Trip).where(Trip.id == trip_id))
    trip = result.scalar_one_or_none()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    if trip.available_seats < 1:
        raise HTTPException(status_code=400, detail="No seats available")

    data = BookingCreate(
        trip_id=trip_id,
        passenger_name=user.full_name,
        passenger_phone=user.phone_number,
        payment_method="simulated",
    )
    booking = Booking(
        id=str(uuid.uuid4()),
        user_id=user.id,
        trip_id=trip_id,
        passenger_name=data.passenger_name,
        passenger_phone=data.passenger_phone,
        total_price=trip.price,
        status="confirmed",
    )
    db.add(booking)

    ticket_code = _generate_ticket_code()
    qr_data = json.dumps({
        "code": ticket_code,
        "trip": trip_id,
        "passenger": user.full_name,
    })
    ticket = Ticket(
        id=str(uuid.uuid4()),
        booking_id=booking.id,
        ticket_code=ticket_code,
        qr_data=qr_data,
        status="active",
    )
    db.add(ticket)

    payment = Payment(
        id=str(uuid.uuid4()),
        booking_id=booking.id,
        amount=trip.price,
        payment_method="simulated",
        status="completed",
        paid_at=datetime.utcnow(),
    )
    db.add(payment)

    trip.available_seats -= 1
    await db.commit()
    return await _refetch_booking(db, booking.id)


async def get_user_bookings(db: AsyncSession, user_id: str) -> List[Booking]:
    result = await db.execute(
        select(Booking)
        .where(Booking.user_id == user_id)
        .options(*_BOOKING_OPTIONS)
        .order_by(Booking.created_at.desc())
    )
    return list(result.scalars().all())


async def get_booking(db: AsyncSession, booking_id: str, user_id: str) -> Booking:
    result = await db.execute(
        select(Booking)
        .where(Booking.id == booking_id, Booking.user_id == user_id)
        .options(*_BOOKING_OPTIONS)
    )
    booking = result.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking


async def cancel_booking(db: AsyncSession, booking_id: str, user_id: str) -> Booking:
    booking = await get_booking(db, booking_id, user_id)
    if booking.status in ("cancelled", "completed"):
        raise HTTPException(status_code=400, detail=f"Cannot cancel a {booking.status} booking")

    booking.status = "cancelled"
    if booking.ticket:
        booking.ticket.status = "cancelled"

    result = await db.execute(select(Trip).where(Trip.id == booking.trip_id))
    trip = result.scalar_one_or_none()
    if trip:
        trip.available_seats += 1

    await db.commit()
    return await _refetch_booking(db, booking_id)


async def reschedule_booking(db: AsyncSession, booking_id: str, user_id: str,
                             new_trip_id: str) -> Booking:
    booking = await get_booking(db, booking_id, user_id)
    if booking.status != "confirmed":
        raise HTTPException(status_code=400, detail="Only confirmed bookings can be rescheduled")

    result = await db.execute(select(Trip).where(Trip.id == new_trip_id))
    new_trip = result.scalar_one_or_none()
    if not new_trip or new_trip.available_seats < 1:
        raise HTTPException(status_code=400, detail="New trip unavailable")

    old_result = await db.execute(select(Trip).where(Trip.id == booking.trip_id))
    old_trip = old_result.scalar_one_or_none()
    if old_trip:
        old_trip.available_seats += 1

    booking.trip_id = new_trip_id
    booking.total_price = new_trip.price
    new_trip.available_seats -= 1

    await db.commit()
    return await _refetch_booking(db, booking_id)


# ── Agency-scoped transactions (used by the agency dashboard) ──────────────────

async def list_agency_bookings(
    db: AsyncSession,
    agency_id: str,
    status: Optional[str] = None,
    payment_method: Optional[str] = None,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    page: int = 1,
    size: int = 20,
) -> Tuple[List[Booking], int]:
    base_query = (
        select(Booking)
        .join(Trip, Booking.trip_id == Trip.id)
        .join(Route, Trip.route_id == Route.id)
        .where(Route.agency_id == agency_id)
    )
    if payment_method:
        base_query = base_query.join(Payment, Payment.booking_id == Booking.id).where(
            Payment.payment_method == payment_method
        )
    if status:
        # Filter by *payment* status — that's what "transaction status" means here.
        base_query = base_query.where(
            Booking.id.in_(select(Payment.booking_id).where(Payment.status == status))
        )
    if from_date:
        base_query = base_query.where(Booking.created_at >= datetime.fromisoformat(from_date))
    if to_date:
        base_query = base_query.where(Booking.created_at <= datetime.fromisoformat(to_date))

    total = (await db.execute(select(func.count()).select_from(base_query.subquery()))).scalar_one()

    query = (
        base_query
        .options(*_BOOKING_OPTIONS)
        .order_by(Booking.created_at.desc())
        .offset((page - 1) * size)
        .limit(size)
    )
    result = await db.execute(query)
    return list(result.scalars().unique().all()), total


async def update_transaction_status(db: AsyncSession, booking_id: str, agency_id: str, new_status: str) -> Booking:
    result = await db.execute(
        select(Booking)
        .join(Trip, Booking.trip_id == Trip.id)
        .join(Route, Trip.route_id == Route.id)
        .where(Booking.id == booking_id, Route.agency_id == agency_id)
        .options(*_BOOKING_OPTIONS)
    )
    booking = result.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Transaction not found for this agency")

    if new_status == "cancelled":
        if booking.status in ("cancelled", "completed"):
            raise HTTPException(status_code=400, detail=f"Cannot cancel a {booking.status} booking")
        booking.status = "cancelled"
        if booking.ticket:
            booking.ticket.status = "cancelled"
        if booking.payment:
            booking.payment.status = "refunded" if booking.payment.status == "completed" else "failed"
        trip_result = await db.execute(select(Trip).where(Trip.id == booking.trip_id))
        trip = trip_result.scalar_one_or_none()
        if trip:
            trip.available_seats += 1
    elif new_status == "completed":
        if not booking.payment:
            raise HTTPException(status_code=400, detail="This transaction has no payment to complete")
        booking.payment.status = "completed"
        booking.payment.paid_at = datetime.utcnow()
        if booking.status == "pending":
            booking.status = "confirmed"
    else:
        raise HTTPException(status_code=400, detail=f"Unsupported status transition: {new_status}")

    await db.commit()
    return await _refetch_booking(db, booking_id)
