from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class AgencyResponse(BaseModel):
    id: str
    name: str
    description: Optional[str]
    logo_url: Optional[str]
    contact_email: Optional[str]
    contact_phone: Optional[str]
    address: Optional[str]
    is_verified: bool
    is_active: bool

    model_config = {"from_attributes": True}


class AgencyCreate(BaseModel):
    name: str
    description: Optional[str] = None
    logo_url: Optional[str] = None
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None
    address: Optional[str] = None
