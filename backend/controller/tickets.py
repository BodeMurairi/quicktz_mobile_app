from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from data.database import get_db
from schemas.ticket import TicketResponse
from models.ticket import Ticket
from models.booking import Booking
from middleware.auth import get_current_user
from models.user import User
from fastapi import HTTPException

router = APIRouter()


@router.get("", response_model=List[TicketResponse])
async def my_tickets(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Ticket)
        .join(Booking, Ticket.booking_id == Booking.id)
        .where(Booking.user_id == current_user.id)
    )
    return list(result.scalars().all())


@router.get("/{ticket_id}", response_model=TicketResponse)
async def ticket_detail(
    ticket_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Ticket)
        .join(Booking, Ticket.booking_id == Booking.id)
        .where(Ticket.id == ticket_id, Booking.user_id == current_user.id)
    )
    ticket = result.scalar_one_or_none()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    return ticket
