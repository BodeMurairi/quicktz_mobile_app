from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from schemas.route import RouteResponse


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
    route: Optional[RouteResponse] = None

    model_config = {"from_attributes": True}


class TripCreate(BaseModel):
    route_id: str
    departure_datetime: datetime
    arrival_datetime: Optional[datetime] = None
    total_seats: int = 50
    price: float
    bus_number: Optional[str] = None


class TripSearch(BaseModel):
    origin: str
    destination: str
    departure_date: str  # YYYY-MM-DD
    passengers: int = 1
