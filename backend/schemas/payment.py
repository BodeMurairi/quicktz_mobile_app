from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class PaymentResponse(BaseModel):
    id: str
    booking_id: str
    amount: float
    currency: str
    payment_method: str
    transaction_id: Optional[str]
    status: str
    paid_at: Optional[datetime]
    created_at: datetime

    model_config = {"from_attributes": True}
