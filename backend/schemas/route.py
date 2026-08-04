from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from schemas.agency import AgencyResponse


class RouteStop(BaseModel):
    name: str
    duration_minutes: Optional[int] = None  # travel time from the previous stop (or from origin, for the first stop)


class RouteSimpleResponse(BaseModel):
    """Route without nested agency — used inside AgencyResponse and by the routes CRUD endpoints."""
    id: str
    agency_id: str
    origin: str
    destination: str
    distance_km: Optional[float]
    duration_minutes: Optional[int]
    stops: Optional[List[RouteStop]] = None
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class RouteResponse(BaseModel):
    id: str
    agency_id: str
    origin: str
    destination: str
    distance_km: Optional[float]
    duration_minutes: Optional[int]
    stops: Optional[List[RouteStop]] = None
    is_active: bool
    agency: Optional[AgencyResponse] = None

    model_config = {"from_attributes": True}


class RouteCreate(BaseModel):
    agency_id: str
    origin: str
    destination: str
    distance_km: Optional[float] = None
    duration_minutes: Optional[int] = None
    stops: Optional[List[RouteStop]] = None


class RouteUpdate(BaseModel):
    origin: Optional[str] = None
    destination: Optional[str] = None
    distance_km: Optional[float] = None
    duration_minutes: Optional[int] = None
    stops: Optional[List[RouteStop]] = None
    is_active: Optional[bool] = None
