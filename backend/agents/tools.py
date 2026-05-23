import contextvars
import json
import random
import string
import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import and_, select
from sqlalchemy.orm import selectinload

from data.database import AsyncSessionLocal
from models.agency import Agency
from models.booking import Booking
from models.payment import Payment
from models.route import Route
from models.ticket import Ticket
from models.trip import Trip
from models.user import User

# Per-request context vars — set by the FastAPI endpoint before running the agent
current_user_id: contextvars.ContextVar[Optional[str]] = contextvars.ContextVar(
    "current_user_id", default=None
)
last_booking_result: contextvars.ContextVar[Optional[dict]] = contextvars.ContextVar(
    "last_booking_result", default=None
)
last_trip_suggestions: contextvars.ContextVar[Optional[list]] = contextvars.ContextVar(
    "last_trip_suggestions", default=None
)
pending_booking_preview: contextvars.ContextVar[Optional[dict]] = contextvars.ContextVar(
    "pending_booking_preview", default=None
)


def _ticket_code() -> str:
    return "QTZ-" + "".join(random.choices(string.ascii_uppercase + string.digits, k=8))


async def search_available_trips(
    origin: str,
    destination: str,
    departure_date: str,
    passengers: int = 1,
    max_price_xof: float = 0,
    wifi_required: bool = False,
    meal_required: bool = False,
    ac_required: bool = False,
) -> dict:
    """
    Search for available bus trips between two Togolese cities.
    departure_date must be in YYYY-MM-DD format.
    Returns a list of matching trips sorted by price.
    """
    try:
        date = datetime.strptime(departure_date, "%Y-%m-%d").date()
    except ValueError:
        return {"error": "Invalid date format — use YYYY-MM-DD", "trips": []}

    day_start = datetime.combine(date, datetime.min.time())
    day_end = datetime.combine(date, datetime.max.time()).replace(microsecond=0)

    filters = [
        Route.origin.ilike(f"%{origin}%"),
        Route.destination.ilike(f"%{destination}%"),
        Trip.available_seats >= max(passengers, 1),
        Trip.is_active == True,
        Trip.status == "scheduled",
        Trip.departure_datetime >= day_start,
        Trip.departure_datetime <= day_end,
    ]
    if max_price_xof > 0:
        filters.append(Trip.price <= max_price_xof)
    if wifi_required:
        filters.append(Trip.has_wifi == True)
    if meal_required:
        filters.append(Trip.has_meal == True)
    if ac_required:
        filters.append(Trip.has_ac == True)

    async with AsyncSessionLocal() as db:
        stmt = (
            select(Trip)
            .join(Trip.route)
            .where(and_(*filters))
            .options(selectinload(Trip.route).selectinload(Route.agency))
            .order_by(Trip.price)
        )
        result = await db.execute(stmt)
        trips = result.scalars().all()

    if not trips:
        return {
            "found": 0,
            "message": (
                f"No trips found from {origin} to {destination} on {departure_date}. "
                "Try a different date or check nearby cities."
            ),
            "trips": [],
        }

    trip_list = [
        {
            "id": t.id,
            "agency": t.route.agency.name if (t.route and t.route.agency) else "Unknown",
            "origin": t.route.origin if t.route else origin,
            "destination": t.route.destination if t.route else destination,
            "departure": t.departure_datetime.strftime("%Y-%m-%d %H:%M"),
            "arrival": t.arrival_datetime.strftime("%Y-%m-%d %H:%M") if t.arrival_datetime else "N/A",
            "price_xof": int(t.price),
            "available_seats": t.available_seats,
            "amenities": {
                "wifi": t.has_wifi,
                "meal": t.has_meal,
                "ac": t.has_ac,
                "usb": t.has_usb,
            },
            "bus_number": t.bus_number or "N/A",
        }
        for t in trips
    ]

    # Surface top results for UI rendering as selectable cards (max 5)
    last_trip_suggestions.set(trip_list[:5])

    return {
        "found": len(trips),
        "origin": origin,
        "destination": destination,
        "date": departure_date,
        "trips": trip_list,
    }


async def get_trip_details(trip_id: str) -> dict:
    """Get full details for a specific trip by its ID."""
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(Trip)
            .where(Trip.id == trip_id)
            .options(selectinload(Trip.route).selectinload(Route.agency))
        )
        trip = result.scalar_one_or_none()

    if not trip:
        return {"error": f"Trip '{trip_id}' not found."}

    return {
        "id": trip.id,
        "agency": trip.route.agency.name if (trip.route and trip.route.agency) else "Unknown",
        "agency_phone": trip.route.agency.contact_phone if (trip.route and trip.route.agency) else None,
        "origin": trip.route.origin if trip.route else "Unknown",
        "destination": trip.route.destination if trip.route else "Unknown",
        "departure": trip.departure_datetime.strftime("%Y-%m-%d %H:%M"),
        "arrival": trip.arrival_datetime.strftime("%Y-%m-%d %H:%M") if trip.arrival_datetime else "N/A",
        "price_xof": int(trip.price),
        "available_seats": trip.available_seats,
        "total_seats": trip.total_seats,
        "amenities": {
            "wifi": trip.has_wifi,
            "meal": trip.has_meal,
            "ac": trip.has_ac,
            "usb": trip.has_usb,
        },
        "bus_number": trip.bus_number or "N/A",
        "status": trip.status,
    }


async def get_available_agencies() -> dict:
    """Get a list of all active bus agencies operating in Togo."""
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(Agency).where(Agency.is_active == True).order_by(Agency.name)
        )
        agencies = result.scalars().all()

    return {
        "found": len(agencies),
        "agencies": [
            {
                "id": a.id,
                "name": a.name,
                "description": a.description,
                "contact_phone": a.contact_phone,
                "contact_email": a.contact_email,
                "address": a.address,
                "is_verified": a.is_verified,
            }
            for a in agencies
        ],
    }


async def get_agency_profile(agency_id: str) -> dict:
    """Get full profile and active routes for a specific agency by its ID."""
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(Agency)
            .where(Agency.id == agency_id)
            .options(selectinload(Agency.routes))
        )
        agency = result.scalar_one_or_none()

    if not agency:
        return {"error": f"Agency '{agency_id}' not found."}

    return {
        "id": agency.id,
        "name": agency.name,
        "description": agency.description,
        "contact_phone": agency.contact_phone,
        "contact_email": agency.contact_email,
        "address": agency.address,
        "is_verified": agency.is_verified,
        "routes": [
            {
                "origin": r.origin,
                "destination": r.destination,
                "distance_km": r.distance_km,
                "duration_minutes": r.duration_minutes,
            }
            for r in agency.routes
            if r.is_active
        ],
    }


async def create_booking_and_simulate_payment(
    trip_id: str,
    passenger_name: str = "",
    passenger_phone: str = "",
    payment_method: str = "mobile_money",
) -> dict:
    """
    Book a trip and simulate payment for the current user.
    If passenger_name / passenger_phone are not provided, the user's profile is used.
    Returns booking confirmation including ticket_code.
    """
    user_id = current_user_id.get()
    if not user_id:
        return {"error": "Authentication required. Please log in first."}

    async with AsyncSessionLocal() as db:
        # Fetch user
        u_result = await db.execute(select(User).where(User.id == user_id))
        user = u_result.scalar_one_or_none()
        if not user:
            return {"error": "User account not found."}

        # Fetch trip
        t_result = await db.execute(
            select(Trip)
            .where(Trip.id == trip_id)
            .options(selectinload(Trip.route).selectinload(Route.agency))
        )
        trip = t_result.scalar_one_or_none()
        if not trip:
            return {"error": f"Trip '{trip_id}' not found."}
        if trip.available_seats < 1:
            return {"error": "No seats available on this trip."}
        if trip.status != "scheduled":
            return {"error": f"Trip is not bookable (status: {trip.status})."}

        pax_name = passenger_name.strip() or user.full_name
        pax_phone = passenger_phone.strip() or (user.phone_number or "")

        booking = Booking(
            id=str(uuid.uuid4()),
            user_id=user_id,
            trip_id=trip_id,
            passenger_name=pax_name,
            passenger_phone=pax_phone,
            total_price=trip.price,
            status="confirmed",
        )
        db.add(booking)

        code = _ticket_code()
        ticket = Ticket(
            id=str(uuid.uuid4()),
            booking_id=booking.id,
            ticket_code=code,
            qr_data=json.dumps({"code": code, "trip": trip_id, "passenger": pax_name}),
            status="active",
        )
        db.add(ticket)

        payment = Payment(
            id=str(uuid.uuid4()),
            booking_id=booking.id,
            amount=trip.price,
            payment_method=payment_method,
            status="completed",
            paid_at=datetime.utcnow(),
        )
        db.add(payment)

        trip.available_seats -= 1
        await db.commit()
        await db.refresh(booking)

        # Clear the pending preview now that the booking is confirmed
        pending_booking_preview.set(None)

        agency_name = trip.route.agency.name if (trip.route and trip.route.agency) else "Unknown"
        result_data = {
            "success": True,
            "booking_id": booking.id,
            "ticket_code": code,
            "passenger_name": pax_name,
            "trip": {
                "origin": trip.route.origin if trip.route else "Unknown",
                "destination": trip.route.destination if trip.route else "Unknown",
                "departure": trip.departure_datetime.strftime("%Y-%m-%d %H:%M"),
                "agency": agency_name,
                "price_xof": int(trip.price),
            },
            "payment_method": payment_method,
            "payment_status": "COMPLETED (Simulated)",
        }

    # Surface the result to the FastAPI endpoint via ContextVar
    last_booking_result.set(result_data)
    return result_data


async def preview_booking(
    trip_id: str,
    passenger_name: str = "",
    passenger_phone: str = "",
    payment_method: str = "mobile_money",
) -> dict:
    """
    Show the user a booking preview card for their review BEFORE confirming.
    Always call this before create_booking_and_simulate_payment.
    The user must explicitly confirm by clicking the confirmation button.
    Returns the trip and passenger details for the user to review.
    """
    user_id = current_user_id.get()
    if not user_id:
        return {"error": "Authentication required. Please log in first."}

    async with AsyncSessionLocal() as db:
        u_result = await db.execute(select(User).where(User.id == user_id))
        user = u_result.scalar_one_or_none()

        t_result = await db.execute(
            select(Trip)
            .where(Trip.id == trip_id)
            .options(selectinload(Trip.route).selectinload(Route.agency))
        )
        trip = t_result.scalar_one_or_none()
        if not trip:
            return {"error": f"Trip '{trip_id}' not found."}
        if trip.available_seats < 1:
            return {"error": "No seats available on this trip."}
        if trip.status != "scheduled":
            return {"error": f"Trip is not bookable (status: {trip.status})."}

        pax_name = passenger_name.strip() or (user.full_name if user else "")
        pax_phone = passenger_phone.strip() or (user.phone_number if user else "") or ""

        preview = {
            "trip_id": trip_id,
            "agency": trip.route.agency.name if (trip.route and trip.route.agency) else "Unknown",
            "origin": trip.route.origin if trip.route else "Unknown",
            "destination": trip.route.destination if trip.route else "Unknown",
            "departure": trip.departure_datetime.strftime("%Y-%m-%d %H:%M"),
            "arrival": trip.arrival_datetime.strftime("%Y-%m-%d %H:%M") if trip.arrival_datetime else "N/A",
            "price_xof": int(trip.price),
            "available_seats": trip.available_seats,
            "passenger_name": pax_name,
            "passenger_phone": pax_phone,
            "payment_method": payment_method,
        }

    pending_booking_preview.set(preview)
    return {
        **preview,
        "preview_ready": True,
        "instruction": (
            "A booking preview card has been shown to the user. "
            "Wait for them to click 'Confirm Booking'. "
            "Do NOT call create_booking_and_simulate_payment until they confirm."
        ),
    }
