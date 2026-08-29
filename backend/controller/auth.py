from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from data.database import get_db
from schemas.auth import (
    RegisterRequest, LoginRequest, TokenResponse, RefreshRequest,
    ForgotPasswordRequest, ResetPasswordRequest,
)
from schemas.user import UserResponse
from services.auth_service import (
    register_user, authenticate_user,
    create_access_token, create_refresh_token, decode_token, get_user_by_id,
    request_password_reset, reset_password,
)
from middleware.auth import get_current_user
from models.user import User

router = APIRouter()


@router.post("/register", response_model=TokenResponse, status_code=201)
async def register(data: RegisterRequest, db: AsyncSession = Depends(get_db)):
    user = await register_user(db, data.full_name, data.password, data.email, data.phone_number)
    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, db: AsyncSession = Depends(get_db)):
    user = await authenticate_user(db, data.identifier, data.password)
    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh(data: RefreshRequest, db: AsyncSession = Depends(get_db)):
    payload = decode_token(data.refresh_token)
    if payload.get("type") != "refresh":
        from fastapi import HTTPException
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    user = await get_user_by_id(db, payload["sub"])
    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


@router.get("/me", response_model=UserResponse)
async def me(current_user: User = Depends(get_current_user)):
    return current_user


@router.post("/forgot-password")
async def forgot_password(data: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    """Always returns the same generic response, whether or not the email is
    registered — otherwise the response itself would leak which emails exist."""
    await request_password_reset(db, data.email)
    return {"detail": "If that email is registered, a reset code has been sent."}


@router.post("/reset-password")
async def reset_password_route(data: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    await reset_password(db, data.email, data.code, data.new_password)
    return {"detail": "Password reset successfully."}
