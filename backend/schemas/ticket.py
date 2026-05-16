from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class TicketResponse(BaseModel):
    id: str
    booking_id: str
    ticket_code: str
    qr_data: Optional[str]
    status: str
    issued_at: datetime
    expires_at: Optional[datetime]

    model_config = {"from_attributes": True}
