import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from data.database import Base


class Conversation(Base):
    __tablename__ = "conversations"
    __table_args__ = (UniqueConstraint("user_id", "agency_id", name="uq_conversation_user_agency"),)

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    agency_id = Column(String, ForeignKey("agencies.id"), nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")
    agency = relationship("Agency")
    messages = relationship(
        "Message", back_populates="conversation", lazy="noload",
        order_by="Message.created_at", cascade="all, delete-orphan",
    )
