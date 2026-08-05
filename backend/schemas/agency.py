from pydantic import BaseModel
from typing import Optional, List, Dict


class AgencyLocation(BaseModel):
    label: str
    address: str
    phone: Optional[str] = None


class AgencyDayHours(BaseModel):
    open: Optional[str] = None   # "HH:MM"
    close: Optional[str] = None  # "HH:MM"
    closed: bool = False


class AgencyResponse(BaseModel):
    id: str
    name: str
    description: Optional[str]
    logo_url: Optional[str]
    contact_email: Optional[str]
    contact_phone: Optional[str]
    address: Optional[str]
    gallery: Optional[List[str]] = None
    locations: Optional[List[AgencyLocation]] = None
    opening_hours: Optional[Dict[str, AgencyDayHours]] = None
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
    gallery: Optional[List[str]] = None
    locations: Optional[List[AgencyLocation]] = None
    opening_hours: Optional[Dict[str, AgencyDayHours]] = None


class AgencyUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    logo_url: Optional[str] = None
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None
    address: Optional[str] = None
    gallery: Optional[List[str]] = None
    locations: Optional[List[AgencyLocation]] = None
    opening_hours: Optional[Dict[str, AgencyDayHours]] = None
