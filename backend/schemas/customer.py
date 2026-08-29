from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class CustomerResponse(BaseModel):
    """A customer isn't its own table — it's derived from who has actually been a
    passenger on a booking for this agency, whether booked from the rider app or
    entered manually by staff. Grouped by phone number (or name, if no phone)."""
    id: str
    user_id: Optional[str] = None  # set only when a real rider account matches — needed to start a conversation
    full_name: str
    email: Optional[str] = None
    phone_number: Optional[str] = None
    booking_count: int
    total_spent: float
    last_travel: Optional[datetime] = None
    is_premium: bool = False
