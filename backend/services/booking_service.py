import uuid
import random
import string
import json
from datetime import datetime
from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from fastapi import HTTPException

from models.booking import Booking
from models.ticket import Ticket
from models.payment import Payment
from models.trip import Trip
from models.user import User
from schemas.booking import BookingCreate


def _generate_ticket_code() -> str:
    return "QTZ-" + "".join(random.choices(string.ascii_uppercase + string.digits, k=8))


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
    await db.refresh(booking)
    return booking


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
    await db.refresh(booking)
    return booking


async def get_user_bookings(db: AsyncSession, user_id: str) -> List[Booking]:
    result = await db.execute(
        select(Booking)
        .where(Booking.user_id == user_id)
        .options(selectinload(Booking.trip), selectinload(Booking.ticket))
        .order_by(Booking.created_at.desc())
    )
    return list(result.scalars().all())


async def get_booking(db: AsyncSession, booking_id: str, user_id: str) -> Booking:
    result = await db.execute(
        select(Booking)
        .where(Booking.id == booking_id, Booking.user_id == user_id)
        .options(selectinload(Booking.trip), selectinload(Booking.ticket), selectinload(Booking.payment))
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
    await db.refresh(booking)
    return booking


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
    await db.refresh(booking)
    return booking
