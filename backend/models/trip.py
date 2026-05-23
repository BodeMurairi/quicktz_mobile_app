import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Float, Integer, ForeignKey
from sqlalchemy.orm import relationship
from data.database import Base


class Trip(Base):
    __tablename__ = "trips"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    route_id = Column(String, ForeignKey("routes.id"), nullable=False)
    departure_datetime = Column(DateTime, nullable=False)
    arrival_datetime = Column(DateTime, nullable=True)
    total_seats = Column(Integer, nullable=False, default=50)
    available_seats = Column(Integer, nullable=False, default=50)
    price = Column(Float, nullable=False)
    bus_number = Column(String, nullable=True)
    status = Column(String, default="scheduled")  # scheduled, departed, completed, cancelled
    has_wifi = Column(Boolean, default=False)
    has_meal = Column(Boolean, default=False)
    has_ac   = Column(Boolean, default=False)
    has_usb  = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    route = relationship("Route", back_populates="trips")
    bookings = relationship("Booking", back_populates="trip", lazy="noload")
