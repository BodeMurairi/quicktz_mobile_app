from pydantic import BaseModel
from typing import Optional
from schemas.agency import AgencyResponse


class RouteSimpleResponse(BaseModel):
    """Route without nested agency — used inside AgencyResponse to avoid circular refs."""
    id: str
    origin: str
    destination: str
    distance_km: Optional[float]
    duration_minutes: Optional[int]
    is_active: bool

    model_config = {"from_attributes": True}


class RouteResponse(BaseModel):
    id: str
    agency_id: str
    origin: str
    destination: str
    distance_km: Optional[float]
    duration_minutes: Optional[int]
    is_active: bool
    agency: Optional[AgencyResponse] = None

    model_config = {"from_attributes": True}


class RouteCreate(BaseModel):
    agency_id: str
    origin: str
    destination: str
    distance_km: Optional[float] = None
    duration_minutes: Optional[int] = None
