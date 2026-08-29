from typing import List
from fastapi import APIRouter, Depends, HTTPException, Response
from fastapi.security import HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from data.database import get_db
from schemas.booking import (
    BookingCreate, BookingResponse, BookingCancelRequest, RescheduleRequest,
    TransactionStatusUpdate, SendTicketEmailRequest,
    ManualBookingCreate, ApproveBookingRequest,
)
from schemas.review import ReviewCreate, ReviewResponse
from schemas.conversation import MessageResponse
from services.booking_service import (
    create_booking, get_user_bookings, get_booking, cancel_booking, reschedule_booking,
    instant_booking, update_transaction_status, _refetch_booking,
    create_manual_booking, approve_booking,
)
from services.review_service import create_review
from services.ticket_pdf_service import generate_ticket_pdf
from services.conversation_service import get_or_create_conversation, send_message_as_agency
from services.email_service import send_email_with_attachment
from services.auth_service import decode_token, get_user_by_id
from services.agency_auth_service import get_agency_by_id
from config.settings import get_settings
from middleware.auth import get_current_user, get_current_agency, require_owns_agency, security
from models.user import User
from models.agency import Agency

router = APIRouter()


@router.post("/simulate/{trip_id}", response_model=BookingResponse, status_code=201)
async def simulate_book(
    trip_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await instant_booking(db, current_user, trip_id)


@router.post("", response_model=BookingResponse, status_code=201)
async def book_trip(
    data: BookingCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await create_booking(db, current_user.id, data)


@router.post("/manual", response_model=BookingResponse, status_code=201)
async def manual_booking(
    data: ManualBookingCreate,
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    """Agency dashboard's manual booking. Ends up pending_approval (rider must
    confirm + pay in-app) when the phone matches a real account, otherwise
    instant-confirmed as before for accountless walk-ins."""
    booking_data = BookingCreate(
        trip_id=data.trip_id,
        passenger_name=data.passenger_name,
        passenger_phone=data.passenger_phone,
        seat_number=data.seat_number,
        payment_method=data.payment_method,
    )
    return await create_manual_booking(db, current_agency.id, booking_data)


@router.post("/{booking_id}/approve", response_model=BookingResponse)
async def approve(
    booking_id: str,
    data: ApproveBookingRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Rider confirms a booking an agency made manually on their behalf, and pays."""
    return await approve_booking(db, booking_id, current_user.id, data.payment_method)


@router.get("", response_model=List[BookingResponse])
async def my_bookings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Rider app: the current user's own bookings. The agency dashboard's
    equivalent (every transaction for an agency) is GET /agencies/{id}/bookings,
    which requires that agency's own login instead."""
    return await get_user_bookings(db, current_user.id)


@router.get("/{booking_id}", response_model=BookingResponse)
async def booking_detail(
    booking_id: str,
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
):
    """Dual-audience: a rider viewing their own booking, or the owning agency
    viewing it from the dashboard — dispatches on the token type."""
    payload = decode_token(credentials.credentials)
    token_type = payload.get("type")
    if token_type == "access":
        user = await get_user_by_id(db, payload["sub"])
        return await get_booking(db, booking_id, user.id)
    if token_type == "agency_access":
        agency = await get_agency_by_id(db, payload["sub"])
        booking, _route = await _get_owned_booking(db, booking_id, agency)
        return booking
    raise HTTPException(status_code=401, detail="Invalid token type")


@router.post("/{booking_id}/cancel", response_model=BookingResponse)
async def cancel(
    booking_id: str,
    data: BookingCancelRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await cancel_booking(db, booking_id, current_user.id)


@router.post("/{booking_id}/reschedule", response_model=BookingResponse)
async def reschedule(
    booking_id: str,
    data: RescheduleRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await reschedule_booking(db, booking_id, current_user.id, data.new_trip_id)


@router.post("/{booking_id}/review", response_model=ReviewResponse, status_code=201)
async def review_booking(
    booking_id: str,
    data: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Rider leaves a rating/comment on a completed (departed) trip."""
    return await create_review(db, booking_id, current_user.id, data)


async def _get_owned_booking(db: AsyncSession, booking_id: str, current_agency: Agency):
    booking = await _refetch_booking(db, booking_id)
    route = booking.trip.route if booking.trip else None
    if not route:
        raise HTTPException(status_code=404, detail="Booking not found for this agency")
    require_owns_agency(current_agency, route.agency_id)
    return booking, route


@router.patch("/{booking_id}/status", response_model=BookingResponse)
async def update_status(
    booking_id: str,
    data: TransactionStatusUpdate,
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    """Agency-scoped: cancel a transaction, or mark a pending one completed."""
    await _get_owned_booking(db, booking_id, current_agency)
    return await update_transaction_status(db, booking_id, current_agency.id, data.status)


@router.get("/{booking_id}/ticket.pdf")
async def download_ticket_pdf(booking_id: str, db: AsyncSession = Depends(get_db)):
    """No auth — the ticket QR/code is already the boarding credential, and this
    URL is what gets embedded in emails and chat messages sent to riders."""
    booking = await _refetch_booking(db, booking_id)
    if not booking.ticket:
        raise HTTPException(status_code=404, detail="No ticket for this booking yet")
    pdf_bytes = generate_ticket_pdf(booking)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="quicktz-{booking.ticket.ticket_code}.pdf"'},
    )


@router.post("/{booking_id}/send-ticket-message", response_model=MessageResponse, status_code=201)
async def send_ticket_message(
    booking_id: str,
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    booking, route = await _get_owned_booking(db, booking_id, current_agency)
    if not booking.ticket:
        raise HTTPException(status_code=400, detail="This booking has no ticket yet")

    conversation = await get_or_create_conversation(db, booking.user_id, current_agency.id)
    ticket_url = f"{get_settings().PUBLIC_API_BASE_URL}/api/v1/bookings/{booking.id}/ticket.pdf"
    return await send_message_as_agency(
        db, conversation.id, current_agency.id,
        text=f"Here's your ticket for {route.origin} → {route.destination}.",
        attachment_url=ticket_url,
        attachment_name=f"quicktz-{booking.ticket.ticket_code}.pdf",
        attachment_type="application/pdf",
    )


@router.post("/{booking_id}/send-ticket-email")
async def send_ticket_email(
    booking_id: str,
    data: SendTicketEmailRequest,
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    booking, route = await _get_owned_booking(db, booking_id, current_agency)
    if not booking.ticket:
        raise HTTPException(status_code=400, detail="This booking has no ticket yet")

    pdf_bytes = generate_ticket_pdf(booking)
    departure_label = (
        booking.trip.departure_datetime.strftime("%a, %-d %b %Y at %H:%M")
        if booking.trip else None
    )
    send_email_with_attachment(
        to=data.to, subject=data.subject, body=data.body,
        attachment_bytes=pdf_bytes, attachment_filename=f"quicktz-{booking.ticket.ticket_code}.pdf",
        passenger_name=booking.passenger_name,
        origin=route.origin, destination=route.destination,
        departure_label=departure_label,
        ticket_code=booking.ticket.ticket_code,
        agency_name=current_agency.name,
    )
    return {"sent": True}
