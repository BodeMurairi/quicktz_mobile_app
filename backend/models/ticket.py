import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from data.database import Base


class Ticket(Base):
    __tablename__ = "tickets"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    booking_id = Column(String, ForeignKey("bookings.id"), nullable=False, unique=True)
    ticket_code = Column(String, unique=True, nullable=False)
    qr_data = Column(Text, nullable=True)
    status = Column(String, default="active")  # active, used, cancelled, expired
    issued_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=True)

    booking = relationship("Booking", back_populates="ticket")
