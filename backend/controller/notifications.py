from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from data.database import get_db
from schemas.notification import NotificationResponse
from services.notification_service import get_user_notifications, mark_all_read, mark_read
from middleware.auth import get_current_user
from models.user import User

router = APIRouter()


@router.get("", response_model=List[NotificationResponse])
async def get_notifications(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_user_notifications(db, current_user.id)


@router.post("/read-all")
async def read_all(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    await mark_all_read(db, current_user.id)
    return {"message": "All notifications marked as read"}


@router.post("/{notif_id}/read", response_model=NotificationResponse)
async def read_one(
    notif_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await mark_read(db, notif_id, current_user.id)
