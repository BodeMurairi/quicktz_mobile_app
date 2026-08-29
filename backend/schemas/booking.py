from pydantic import BaseModel
from typing import Optional
from datetime import datetime

from schemas.trip import TripResponse
from schemas.payment import PaymentResponse
from schemas.ticket import TicketResponse
from schemas.review import ReviewSummary


class BookingCreate(BaseModel):
    trip_id: str
    passenger_name: str
    passenger_phone: Optional[str] = None
    seat_number: Optional[int] = None
    payment_method: str  # tmoney, flooz, bank_transfer


class BookingResponse(BaseModel):
    id: str
    user_id: Optional[str] = None
    trip_id: str
    seat_number: Optional[int]
    passenger_name: str
    passenger_phone: Optional[str]
    total_price: float
    status: str
    created_at: datetime
    updated_at: datetime
    trip: Optional[TripResponse] = None
    payment: Optional[PaymentResponse] = None
    ticket: Optional[TicketResponse] = None
    review: Optional[ReviewSummary] = None

    model_config = {"from_attributes": True}


class BookingCancelRequest(BaseModel):
    reason: Optional[str] = None


class RescheduleRequest(BaseModel):
    new_trip_id: str


class TransactionStatusUpdate(BaseModel):
    status: str  # "cancelled" | "completed"


class ManualBookingCreate(BaseModel):
    trip_id: str
    passenger_name: str
    passenger_phone: Optional[str] = None
    seat_number: Optional[int] = None
    payment_method: str


class ApproveBookingRequest(BaseModel):
    payment_method: str


class SendTicketEmailRequest(BaseModel):
    to: str
    subject: str
    body: str
