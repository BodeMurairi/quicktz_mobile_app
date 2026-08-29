from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from data.database import get_db
from schemas.auth import TokenResponse, RefreshRequest
from schemas.agency import (
    AgencyRegisterRequest, AgencyLoginRequest, AgencyMeResponse,
    AgencyForgotPasswordRequest, AgencyResetPasswordRequest,
)
from services.agency_auth_service import (
    register_agency, authenticate_agency, get_agency_by_id,
    create_agency_access_token, create_agency_refresh_token, decode_token,
    request_agency_password_reset, reset_agency_password,
)
from middleware.auth import get_current_agency
from models.agency import Agency

router = APIRouter()


@router.post("/register", response_model=TokenResponse, status_code=201)
async def register(data: AgencyRegisterRequest, db: AsyncSession = Depends(get_db)):
    agency = await register_agency(db, data)
    return TokenResponse(
        access_token=create_agency_access_token(agency.id),
        refresh_token=create_agency_refresh_token(agency.id),
    )


@router.post("/login", response_model=TokenResponse)
async def login(data: AgencyLoginRequest, db: AsyncSession = Depends(get_db)):
    agency = await authenticate_agency(db, data.login_email, data.password)
    return TokenResponse(
        access_token=create_agency_access_token(agency.id),
        refresh_token=create_agency_refresh_token(agency.id),
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh(data: RefreshRequest, db: AsyncSession = Depends(get_db)):
    payload = decode_token(data.refresh_token)
    if payload.get("type") != "agency_refresh":
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    agency = await get_agency_by_id(db, payload["sub"])
    return TokenResponse(
        access_token=create_agency_access_token(agency.id),
        refresh_token=create_agency_refresh_token(agency.id),
    )


@router.get("/me", response_model=AgencyMeResponse)
async def me(current_agency: Agency = Depends(get_current_agency)):
    return current_agency


@router.post("/forgot-password")
async def forgot_password(data: AgencyForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    """Always returns the same generic response, whether or not the email is
    registered — otherwise the response itself would leak which emails exist."""
    await request_agency_password_reset(db, data.login_email)
    return {"detail": "If that email is registered, a reset code has been sent."}


@router.post("/reset-password")
async def reset_password_route(data: AgencyResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    await reset_agency_password(db, data.login_email, data.code, data.new_password)
    return {"detail": "Password reset successfully."}
