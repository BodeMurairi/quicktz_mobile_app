from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ConversationCreate(BaseModel):
    agency_id: str


class AgencyConversationCreate(BaseModel):
    user_id: str


class MessageCreate(BaseModel):
    text: str
    attachment_url: Optional[str] = None
    attachment_name: Optional[str] = None
    attachment_type: Optional[str] = None


class AgencyMessageCreate(BaseModel):
    text: str
    attachment_url: Optional[str] = None
    attachment_name: Optional[str] = None
    attachment_type: Optional[str] = None


class MessageResponse(BaseModel):
    id: str
    conversation_id: str
    sender: str  # "user" | "agency"
    text: str
    is_read: bool
    attachment_url: Optional[str] = None
    attachment_name: Optional[str] = None
    attachment_type: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class ConversationResponse(BaseModel):
    """Rider-facing view — who they're talking to (the agency)."""
    id: str
    user_id: str
    agency_id: str
    agency_name: str
    created_at: datetime
    last_message: Optional[MessageResponse] = None
    unread_count: int = 0


class AgencyConversationResponse(BaseModel):
    """Agency-facing view — who they're talking to (the rider)."""
    id: str
    user_id: str
    agency_id: str
    customer_name: str
    created_at: datetime
    last_message: Optional[MessageResponse] = None
    unread_count: int = 0
