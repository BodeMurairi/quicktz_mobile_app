import uuid
from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from models.notification import Notification
from schemas.notification import NotificationCreate


async def get_user_notifications(db: AsyncSession, user_id: str) -> List[Notification]:
    result = await db.execute(
        select(Notification)
        .where(Notification.user_id == user_id)
        .order_by(Notification.created_at.desc())
    )
    return list(result.scalars().all())


async def create_notification(db: AsyncSession, data: NotificationCreate) -> Notification:
    notif = Notification(id=str(uuid.uuid4()), **data.model_dump())
    db.add(notif)
    await db.commit()
    await db.refresh(notif)
    return notif


async def mark_all_read(db: AsyncSession, user_id: str) -> None:
    result = await db.execute(
        select(Notification).where(Notification.user_id == user_id, Notification.is_read == False)
    )
    for notif in result.scalars().all():
        notif.is_read = True
    await db.commit()


async def mark_read(db: AsyncSession, notif_id: str, user_id: str) -> Notification:
    result = await db.execute(
        select(Notification).where(Notification.id == notif_id, Notification.user_id == user_id)
    )
    notif = result.scalar_one_or_none()
    if notif:
        notif.is_read = True
        await db.commit()
        await db.refresh(notif)
    return notif
