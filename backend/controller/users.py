from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from data.database import get_db
from schemas.user import UserResponse, UserUpdate
from services.user_service import update_user, upgrade_to_premium
from middleware.auth import get_current_user
from models.user import User

router = APIRouter()


@router.get("/me", response_model=UserResponse)
async def get_profile(current_user: User = Depends(get_current_user)):
    return current_user


@router.patch("/me", response_model=UserResponse)
async def update_profile(
    data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await update_user(db, current_user.id, data)


@router.post("/me/upgrade-premium", response_model=UserResponse)
async def upgrade(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    return await upgrade_to_premium(db, current_user.id)
