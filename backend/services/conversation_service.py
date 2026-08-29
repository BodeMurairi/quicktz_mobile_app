import uuid
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from fastapi import HTTPException

from models.conversation import Conversation
from models.message import Message
from models.user import User
from models.agency import Agency
from schemas.conversation import (
    ConversationResponse, AgencyConversationResponse, MessageResponse,
)
from schemas.notification import NotificationCreate
from services.notification_service import create_notification

_CONV_OPTIONS = (
    selectinload(Conversation.user),
    selectinload(Conversation.agency),
)


async def _last_message(db: AsyncSession, conversation_id: str) -> Optional[Message]:
    result = await db.execute(
        select(Message)
        .where(Message.conversation_id == conversation_id)
        .order_by(Message.created_at.desc())
        .limit(1)
    )
    return result.scalar_one_or_none()


async def _unread_count(db: AsyncSession, conversation_id: str, unread_from: str) -> int:
    result = await db.execute(
        select(func.count(Message.id)).where(
            Message.conversation_id == conversation_id,
            Message.sender == unread_from,
            Message.is_read == False,  # noqa: E712
        )
    )
    return result.scalar_one()


async def get_or_create_conversation(db: AsyncSession, user_id: str, agency_id: str) -> Conversation:
    result = await db.execute(
        select(Conversation)
        .where(Conversation.user_id == user_id, Conversation.agency_id == agency_id)
        .options(*_CONV_OPTIONS)
    )
    conversation = result.scalar_one_or_none()
    if conversation:
        return conversation

    agency_result = await db.execute(select(Agency).where(Agency.id == agency_id))
    if not agency_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Agency not found")

    user_result = await db.execute(select(User).where(User.id == user_id))
    if not user_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="User not found")

    conversation = Conversation(id=str(uuid.uuid4()), user_id=user_id, agency_id=agency_id)
    db.add(conversation)
    await db.commit()

    result = await db.execute(
        select(Conversation).where(Conversation.id == conversation.id).options(*_CONV_OPTIONS)
    )
    return result.scalar_one()


async def list_user_conversations(db: AsyncSession, user_id: str) -> List[ConversationResponse]:
    result = await db.execute(
        select(Conversation).where(Conversation.user_id == user_id).options(*_CONV_OPTIONS)
    )
    conversations = list(result.scalars().all())

    responses = []
    for c in conversations:
        last = await _last_message(db, c.id)
        unread = await _unread_count(db, c.id, unread_from="agency")
        responses.append(ConversationResponse(
            id=c.id,
            user_id=c.user_id,
            agency_id=c.agency_id,
            agency_name=c.agency.name if c.agency else "Agency",
            created_at=c.created_at,
            last_message=MessageResponse.model_validate(last) if last else None,
            unread_count=unread,
        ))
    responses.sort(key=lambda r: r.last_message.created_at if r.last_message else r.created_at, reverse=True)
    return responses


async def list_agency_conversations(db: AsyncSession, agency_id: str) -> List[AgencyConversationResponse]:
    result = await db.execute(
        select(Conversation).where(Conversation.agency_id == agency_id).options(*_CONV_OPTIONS)
    )
    conversations = list(result.scalars().all())

    responses = []
    for c in conversations:
        last = await _last_message(db, c.id)
        unread = await _unread_count(db, c.id, unread_from="user")
        responses.append(AgencyConversationResponse(
            id=c.id,
            user_id=c.user_id,
            agency_id=c.agency_id,
            customer_name=c.user.full_name if c.user else "Customer",
            created_at=c.created_at,
            last_message=MessageResponse.model_validate(last) if last else None,
            unread_count=unread,
        ))
    responses.sort(key=lambda r: r.last_message.created_at if r.last_message else r.created_at, reverse=True)
    return responses


async def _get_conversation(db: AsyncSession, conversation_id: str) -> Conversation:
    result = await db.execute(select(Conversation).where(Conversation.id == conversation_id))
    conversation = result.scalar_one_or_none()
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return conversation


async def get_messages_as_user(db: AsyncSession, conversation_id: str, user_id: str) -> List[Message]:
    conversation = await _get_conversation(db, conversation_id)
    if conversation.user_id != user_id:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return await _fetch_and_mark_read(db, conversation_id, mark_sender="agency")


async def get_messages_as_agency(db: AsyncSession, conversation_id: str, agency_id: str) -> List[Message]:
    conversation = await _get_conversation(db, conversation_id)
    if conversation.agency_id != agency_id:
        raise HTTPException(status_code=404, detail="Conversation not found for this agency")
    return await _fetch_and_mark_read(db, conversation_id, mark_sender="user")


async def _fetch_and_mark_read(db: AsyncSession, conversation_id: str, mark_sender: str) -> List[Message]:
    result = await db.execute(
        select(Message)
        .where(Message.conversation_id == conversation_id)
        .order_by(Message.created_at.asc())
    )
    messages = list(result.scalars().all())

    unread = [m for m in messages if m.sender == mark_sender and not m.is_read]
    if unread:
        for m in unread:
            m.is_read = True
        await db.commit()

    return messages


async def send_message_as_user(
    db: AsyncSession, conversation_id: str, user_id: str, text: str,
    attachment_url: Optional[str] = None, attachment_name: Optional[str] = None,
    attachment_type: Optional[str] = None,
) -> Message:
    conversation = await _get_conversation(db, conversation_id)
    if conversation.user_id != user_id:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return await _create_message(
        db, conversation_id, sender="user", text=text,
        attachment_url=attachment_url, attachment_name=attachment_name, attachment_type=attachment_type,
    )


async def send_message_as_agency(
    db: AsyncSession, conversation_id: str, agency_id: str, text: str,
    attachment_url: Optional[str] = None, attachment_name: Optional[str] = None,
    attachment_type: Optional[str] = None,
) -> Message:
    conversation = await _get_conversation(db, conversation_id)
    if conversation.agency_id != agency_id:
        raise HTTPException(status_code=404, detail="Conversation not found for this agency")
    message = await _create_message(
        db, conversation_id, sender="agency", text=text,
        attachment_url=attachment_url, attachment_name=attachment_name, attachment_type=attachment_type,
    )

    agency_result = await db.execute(select(Agency).where(Agency.id == agency_id))
    agency = agency_result.scalar_one_or_none()
    await create_notification(db, NotificationCreate(
        user_id=conversation.user_id,
        title=f"New message from {agency.name if agency else 'your agency'}",
        body=text[:140],
        type="message",
    ))
    return message


async def _create_message(
    db: AsyncSession, conversation_id: str, sender: str, text: str,
    attachment_url: Optional[str] = None, attachment_name: Optional[str] = None,
    attachment_type: Optional[str] = None,
) -> Message:
    message = Message(
        id=str(uuid.uuid4()),
        conversation_id=conversation_id,
        sender=sender,
        text=text,
        attachment_url=attachment_url,
        attachment_name=attachment_name,
        attachment_type=attachment_type,
    )
    db.add(message)
    await db.commit()
    await db.refresh(message)
    return message
