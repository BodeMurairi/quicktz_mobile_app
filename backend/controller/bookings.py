from typing import List, Optional
from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.ext.asyncio import AsyncSession

from data.database import get_db
from schemas.booking import (
    BookingCreate, BookingResponse, BookingCancelRequest, RescheduleRequest,
    TransactionStatusUpdate,
)
from services.booking_service import (
    create_booking, get_user_bookings, get_booking, cancel_booking, reschedule_booking,
    instant_booking, list_agency_bookings, update_transaction_status,
)
from middleware.auth import get_current_user
from models.user import User

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


@router.get("", response_model=List[BookingResponse])
async def my_bookings(
    response: Response,
    agency_id: Optional[str] = Query(None),
    status: Optional[str] = Query(None, description="Filters by payment status"),
    payment_method: Optional[str] = Query(None),
    from_date: Optional[str] = Query(None),
    to_date: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Agency dashboard: every transaction for the agency, paginated + filtered.
    if agency_id:
        bookings, total = await list_agency_bookings(
            db, agency_id, status, payment_method, from_date, to_date, page, size
        )
        response.headers["X-Total-Count"] = str(total)
        return bookings
    # Rider app: the current user's own bookings.
    return await get_user_bookings(db, current_user.id)


@router.get("/{booking_id}", response_model=BookingResponse)
async def booking_detail(
    booking_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_booking(db, booking_id, current_user.id)


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


@router.patch("/{booking_id}/status", response_model=BookingResponse)
async def update_status(
    booking_id: str,
    data: TransactionStatusUpdate,
    db: AsyncSession = Depends(get_db),
):
    """Agency-scoped: cancel a transaction, or mark a pending one completed."""
    return await update_transaction_status(db, booking_id, data.agency_id, data.status)
