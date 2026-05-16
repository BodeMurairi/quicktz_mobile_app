import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Float, ForeignKey
from sqlalchemy.orm import relationship
from data.database import Base


class Payment(Base):
    __tablename__ = "payments"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    booking_id = Column(String, ForeignKey("bookings.id"), nullable=False, unique=True)
    amount = Column(Float, nullable=False)
    currency = Column(String, default="XOF")
    payment_method = Column(String, nullable=False)  # tmoney, flooz, bank_transfer
    transaction_id = Column(String, nullable=True, unique=True)
    status = Column(String, default="pending")  # pending, completed, failed, refunded
    paid_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    booking = relationship("Booking", back_populates="payment")
