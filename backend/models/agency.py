import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Text, JSON
from sqlalchemy.orm import relationship
from data.database import Base


class Agency(Base):
    __tablename__ = "agencies"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    login_email = Column(String, unique=True, nullable=True, index=True)
    password_hash = Column(String, nullable=True)
    reset_code_hash = Column(String, nullable=True)
    reset_code_expires_at = Column(DateTime, nullable=True)
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    logo_url = Column(String, nullable=True)
    contact_email = Column(String, nullable=True)
    contact_phone = Column(String, nullable=True)
    address = Column(String, nullable=True)
    gallery = Column(JSON, nullable=True)  # [str, ...] photo URLs
    locations = Column(JSON, nullable=True)  # [{"label": str, "address": str, "phone": str|null}, ...]
    contacts = Column(JSON, nullable=True)  # [{"label": str, "phone": str|null, "email": str|null}, ...] additional contacts (branches, departments, etc.)
    opening_hours = Column(JSON, nullable=True)  # {"monday": {"open": "08:00", "close": "18:00", "closed": false}, ...}
    is_verified = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    routes = relationship("Route", back_populates="agency", lazy="selectin")
