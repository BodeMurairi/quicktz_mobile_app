from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from data.database import get_db
from schemas.conversation import (
    ConversationCreate, ConversationResponse, MessageCreate, MessageResponse,
)
from services.conversation_service import (
    get_or_create_conversation, list_user_conversations,
    get_messages_as_user, send_message_as_user,
)
from middleware.auth import get_current_user
from models.user import User

router = APIRouter()


@router.get("", response_model=List[ConversationResponse])
async def my_conversations(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await list_user_conversations(db, current_user.id)


@router.post("", response_model=ConversationResponse, status_code=201)
async def start_conversation(
    data: ConversationCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    conversation = await get_or_create_conversation(db, current_user.id, data.agency_id)
    conversations = await list_user_conversations(db, current_user.id)
    return next(c for c in conversations if c.id == conversation.id)


@router.get("/{conversation_id}/messages", response_model=List[MessageResponse])
async def conversation_messages(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_messages_as_user(db, conversation_id, current_user.id)


@router.post("/{conversation_id}/messages", response_model=MessageResponse, status_code=201)
async def send_message(
    conversation_id: str,
    data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await send_message_as_user(
        db, conversation_id, current_user.id, data.text,
        attachment_url=data.attachment_url, attachment_name=data.attachment_name,
        attachment_type=data.attachment_type,
    )
