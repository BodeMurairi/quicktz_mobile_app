from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class ReviewCreate(BaseModel):
    rating: int = Field(ge=1, le=5)
    comment: Optional[str] = None


class ReviewReplyRequest(BaseModel):
    reply: str


class ReviewSummary(BaseModel):
    """Minimal shape nested inside a rider's own BookingResponse — the booking already
    carries the customer identity and trip route, no need to restate them here."""
    id: str
    rating: int
    comment: Optional[str] = None
    reply: Optional[str] = None
    replied_at: Optional[datetime] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class ReviewResponse(ReviewSummary):
    """Full shape for agency-facing listings — who wrote it and about which trip."""
    booking_id: str
    agency_id: str
    user_id: str
    customer_name: str
    trip_route: str


class AgencyRatingSummary(BaseModel):
    agency_id: str
    average_rating: Optional[float] = None
    review_count: int = 0
