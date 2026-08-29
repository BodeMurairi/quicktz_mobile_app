from pydantic import BaseModel
from typing import Optional, List, Dict


class AgencyLocation(BaseModel):
    label: str
    address: str
    phone: Optional[str] = None


class AgencyContact(BaseModel):
    label: str
    phone: Optional[str] = None
    email: Optional[str] = None


class AgencyDayHours(BaseModel):
    open: Optional[str] = None   # "HH:MM"
    close: Optional[str] = None  # "HH:MM"
    closed: bool = False


class AgencyResponse(BaseModel):
    """Public shape — never includes login_email/password_hash. Safe for riders
    browsing agencies (mobile app) as well as the agency's own dashboard."""
    id: str
    name: str
    description: Optional[str]
    logo_url: Optional[str]
    contact_email: Optional[str]
    contact_phone: Optional[str]
    address: Optional[str]
    gallery: Optional[List[str]] = None
    locations: Optional[List[AgencyLocation]] = None
    contacts: Optional[List[AgencyContact]] = None
    opening_hours: Optional[Dict[str, AgencyDayHours]] = None
    is_verified: bool
    is_active: bool

    model_config = {"from_attributes": True}


class AgencyMeResponse(AgencyResponse):
    """Authenticated agency's view of itself — includes its own login email."""
    login_email: str


class AgencyCreate(BaseModel):
    name: str
    description: Optional[str] = None
    logo_url: Optional[str] = None
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None
    address: Optional[str] = None
    gallery: Optional[List[str]] = None
    locations: Optional[List[AgencyLocation]] = None
    contacts: Optional[List[AgencyContact]] = None
    opening_hours: Optional[Dict[str, AgencyDayHours]] = None


class AgencyRegisterRequest(AgencyCreate):
    login_email: str
    password: str


class AgencyLoginRequest(BaseModel):
    login_email: str
    password: str


class AgencyForgotPasswordRequest(BaseModel):
    login_email: str


class AgencyResetPasswordRequest(BaseModel):
    login_email: str
    code: str
    new_password: str


class AgencyUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    logo_url: Optional[str] = None
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None
    address: Optional[str] = None
    gallery: Optional[List[str]] = None
    locations: Optional[List[AgencyLocation]] = None
    contacts: Optional[List[AgencyContact]] = None
    opening_hours: Optional[Dict[str, AgencyDayHours]] = None
