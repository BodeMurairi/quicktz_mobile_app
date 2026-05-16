import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Float, Integer, ForeignKey
from sqlalchemy.orm import relationship
from data.database import Base


class Booking(Base):
    __tablename__ = "bookings"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    trip_id = Column(String, ForeignKey("trips.id"), nullable=False)
    seat_number = Column(Integer, nullable=True)
    passenger_name = Column(String, nullable=False)
    passenger_phone = Column(String, nullable=True)
    total_price = Column(Float, nullable=False)
    status = Column(String, default="pending")  # pending, confirmed, cancelled, completed
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="bookings")
    trip = relationship("Trip", back_populates="bookings")
    ticket = relationship("Ticket", back_populates="booking", uselist=False, lazy="selectin")
    payment = relationship("Payment", back_populates="booking", uselist=False, lazy="selectin")
