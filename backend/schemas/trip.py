from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from schemas.route import RouteResponse


class TripRequirement(BaseModel):
    label: str
    value: str


class TripResponse(BaseModel):
    id: str
    route_id: str
    departure_datetime: datetime
    arrival_datetime: Optional[datetime]
    total_seats: int
    available_seats: int
    price: float
    bus_number: Optional[str]
    status: str
    has_wifi: bool = False
    has_meal: bool = False
    has_ac:   bool = False
    has_usb:  bool = False
    requirements: Optional[List[TripRequirement]] = None
    route: Optional[RouteResponse] = None

    model_config = {"from_attributes": True}


class TripCreate(BaseModel):
    route_id: str
    departure_datetime: datetime
    arrival_datetime: Optional[datetime] = None
    total_seats: int = 50
    price: float
    bus_number: Optional[str] = None
    has_wifi: bool = False
    has_meal: bool = False
    has_ac: bool = False
    has_usb: bool = False
    requirements: Optional[List[TripRequirement]] = None


class TripUpdate(BaseModel):
    status: Optional[str] = None
    available_seats: Optional[int] = None
    price: Optional[float] = None
    departure_datetime: Optional[datetime] = None
    arrival_datetime: Optional[datetime] = None
    requirements: Optional[List[TripRequirement]] = None


class TripSearch(BaseModel):
    origin: str
    destination: str
    departure_date: str  # YYYY-MM-DD
    passengers: int = 1
