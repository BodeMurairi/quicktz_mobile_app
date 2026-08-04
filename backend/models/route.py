import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Float, Integer, ForeignKey, JSON
from sqlalchemy.orm import relationship
from data.database import Base


class Route(Base):
    __tablename__ = "routes"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    agency_id = Column(String, ForeignKey("agencies.id"), nullable=False)
    origin = Column(String, nullable=False, index=True)
    destination = Column(String, nullable=False, index=True)
    distance_km = Column(Float, nullable=True)
    duration_minutes = Column(Integer, nullable=True)
    stops = Column(JSON, nullable=True)  # [{"name": str, "duration_minutes": int}, ...] in travel order
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    agency = relationship("Agency", back_populates="routes")
    trips = relationship("Trip", back_populates="route", lazy="noload")
