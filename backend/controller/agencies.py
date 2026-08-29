from typing import List, Optional
from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.ext.asyncio import AsyncSession

from data.database import get_db
from schemas.agency import AgencyResponse, AgencyUpdate
from schemas.route import RouteSimpleResponse
from schemas.review import ReviewResponse, ReviewReplyRequest, AgencyRatingSummary
from schemas.conversation import (
    AgencyConversationResponse, MessageResponse, AgencyMessageCreate, AgencyConversationCreate,
)
from schemas.customer import CustomerResponse
from schemas.analytics import DashboardStats, FinanceSummary
from schemas.trip import TripResponse
from schemas.booking import BookingResponse
from services.agency_service import list_agencies, get_agency, get_agency_routes, update_agency
from services.review_service import list_agency_reviews, reply_to_review, get_agency_rating_summary
from services.conversation_service import (
    list_agency_conversations, get_messages_as_agency, send_message_as_agency,
    get_or_create_conversation,
)
from services.customer_service import list_agency_customers
from services.analytics_service import get_dashboard_stats, get_finance_summary
from services.trip_service import list_trips
from services.booking_service import list_agency_bookings
from middleware.auth import get_current_agency, require_owns_agency
from models.agency import Agency

router = APIRouter()

# ── Public reads — riders browse these (mobile app + web rider-facing pages) ────


@router.get("", response_model=List[AgencyResponse])
async def get_agencies(db: AsyncSession = Depends(get_db)):
    return await list_agencies(db)


@router.get("/{agency_id}", response_model=AgencyResponse)
async def get_agency_detail(agency_id: str, db: AsyncSession = Depends(get_db)):
    return await get_agency(db, agency_id)


@router.get("/{agency_id}/routes", response_model=list[RouteSimpleResponse])
async def get_routes_for_agency(agency_id: str, db: AsyncSession = Depends(get_db)):
    return await get_agency_routes(db, agency_id)


@router.get("/{agency_id}/reviews", response_model=List[ReviewResponse])
async def get_agency_reviews(agency_id: str, db: AsyncSession = Depends(get_db)):
    return await list_agency_reviews(db, agency_id)


@router.get("/{agency_id}/rating-summary", response_model=AgencyRatingSummary)
async def get_agency_rating(agency_id: str, db: AsyncSession = Depends(get_db)):
    return await get_agency_rating_summary(db, agency_id)


# ── Dashboard-only — require the agency's own login, not just any agency_id ─────


@router.patch("/{agency_id}", response_model=AgencyResponse)
async def update_existing_agency(
    agency_id: str,
    data: AgencyUpdate,
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    require_owns_agency(current_agency, agency_id)
    return await update_agency(db, agency_id, data)


@router.patch("/{agency_id}/reviews/{review_id}/reply", response_model=ReviewResponse)
async def reply_agency_review(
    agency_id: str,
    review_id: str,
    data: ReviewReplyRequest,
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    require_owns_agency(current_agency, agency_id)
    return await reply_to_review(db, review_id, agency_id, data.reply)


@router.get("/{agency_id}/analytics/dashboard", response_model=DashboardStats)
async def get_dashboard_analytics(
    agency_id: str,
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    require_owns_agency(current_agency, agency_id)
    return await get_dashboard_stats(db, agency_id)


@router.get("/{agency_id}/analytics/finance", response_model=FinanceSummary)
async def get_finance_analytics(
    agency_id: str,
    period: str = Query("monthly", pattern="^(weekly|monthly|quarterly|yearly)$"),
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    require_owns_agency(current_agency, agency_id)
    return await get_finance_summary(db, agency_id, period)


@router.get("/{agency_id}/trips", response_model=List[TripResponse])
async def get_agency_trips(
    agency_id: str,
    route_id: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    from_date: Optional[str] = Query(None),
    to_date: Optional[str] = Query(None),
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    """Dashboard: every trip for this agency, any status (unlike the public feed)."""
    require_owns_agency(current_agency, agency_id)
    return await list_trips(db, agency_id, route_id, status, from_date, to_date)


@router.get("/{agency_id}/bookings", response_model=List[BookingResponse])
async def get_agency_bookings(
    agency_id: str,
    response: Response,
    status: Optional[str] = Query(None, description="Filters by payment status"),
    payment_method: Optional[str] = Query(None),
    from_date: Optional[str] = Query(None),
    to_date: Optional[str] = Query(None),
    passenger_phone: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    """Dashboard: every transaction/booking for this agency, paginated + filtered."""
    require_owns_agency(current_agency, agency_id)
    bookings, total = await list_agency_bookings(
        db, agency_id, status, payment_method, from_date, to_date, passenger_phone, page, size
    )
    response.headers["X-Total-Count"] = str(total)
    return bookings


@router.get("/{agency_id}/customers", response_model=List[CustomerResponse])
async def get_agency_customers(
    agency_id: str,
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    require_owns_agency(current_agency, agency_id)
    return await list_agency_customers(db, agency_id)


@router.get("/{agency_id}/conversations", response_model=List[AgencyConversationResponse])
async def get_agency_conversations(
    agency_id: str,
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    require_owns_agency(current_agency, agency_id)
    return await list_agency_conversations(db, agency_id)


@router.post("/{agency_id}/conversations", response_model=AgencyConversationResponse, status_code=201)
async def start_agency_conversation(
    agency_id: str,
    data: AgencyConversationCreate,
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    require_owns_agency(current_agency, agency_id)
    conversation = await get_or_create_conversation(db, data.user_id, agency_id)
    conversations = await list_agency_conversations(db, agency_id)
    return next(c for c in conversations if c.id == conversation.id)


@router.get("/{agency_id}/conversations/{conversation_id}/messages", response_model=List[MessageResponse])
async def get_agency_conversation_messages(
    agency_id: str,
    conversation_id: str,
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    require_owns_agency(current_agency, agency_id)
    return await get_messages_as_agency(db, conversation_id, agency_id)


@router.post(
    "/{agency_id}/conversations/{conversation_id}/messages",
    response_model=MessageResponse,
    status_code=201,
)
async def send_agency_conversation_message(
    agency_id: str,
    conversation_id: str,
    data: AgencyMessageCreate,
    current_agency: Agency = Depends(get_current_agency),
    db: AsyncSession = Depends(get_db),
):
    require_owns_agency(current_agency, agency_id)
    return await send_message_as_agency(
        db, conversation_id, agency_id, data.text,
        attachment_url=data.attachment_url, attachment_name=data.attachment_name,
        attachment_type=data.attachment_type,
    )
