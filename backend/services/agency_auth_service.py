import secrets
import uuid
from datetime import datetime, timedelta
from jose import jwt
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status

from models.agency import Agency
from config.settings import settings
from schemas.agency import AgencyRegisterRequest
# Reused as-is — these are entity-agnostic (just work on plain strings/tokens).
from services.auth_service import hash_password, verify_password, decode_token, RESET_CODE_EXPIRE_MINUTES  # noqa: F401


def create_agency_access_token(agency_id: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode(
        {"sub": agency_id, "exp": expire, "type": "agency_access"},
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )


def create_agency_refresh_token(agency_id: str) -> str:
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    return jwt.encode(
        {"sub": agency_id, "exp": expire, "type": "agency_refresh"},
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )


async def register_agency(db: AsyncSession, data: AgencyRegisterRequest) -> Agency:
    existing = await db.execute(select(Agency).where(Agency.login_email == data.login_email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="An agency is already registered with this email")

    fields = data.model_dump(exclude={"login_email", "password"})
    agency = Agency(
        id=str(uuid.uuid4()),
        login_email=data.login_email,
        password_hash=hash_password(data.password),
        **fields,
    )
    db.add(agency)
    await db.commit()
    await db.refresh(agency)
    return agency


async def authenticate_agency(db: AsyncSession, login_email: str, password: str) -> Agency:
    result = await db.execute(select(Agency).where(Agency.login_email == login_email))
    agency = result.scalar_one_or_none()
    if not agency or not agency.password_hash or not verify_password(password, agency.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if not agency.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account disabled")
    return agency


async def get_agency_by_id(db: AsyncSession, agency_id: str) -> Agency:
    result = await db.execute(select(Agency).where(Agency.id == agency_id))
    agency = result.scalar_one_or_none()
    if not agency:
        raise HTTPException(status_code=404, detail="Agency not found")
    return agency


async def request_agency_password_reset(db: AsyncSession, login_email: str) -> None:
    """Silently no-ops if the email isn't registered, so callers can't use this
    to probe which agency accounts exist in the system."""
    result = await db.execute(select(Agency).where(Agency.login_email == login_email))
    agency = result.scalar_one_or_none()
    if not agency:
        return

    code = f"{secrets.randbelow(1_000_000):06d}"
    agency.reset_code_hash = hash_password(code)
    agency.reset_code_expires_at = datetime.utcnow() + timedelta(minutes=RESET_CODE_EXPIRE_MINUTES)
    await db.commit()

    from services.email_service import send_password_reset_email
    send_password_reset_email(login_email, agency.name, code)


async def reset_agency_password(db: AsyncSession, login_email: str, code: str, new_password: str) -> None:
    result = await db.execute(select(Agency).where(Agency.login_email == login_email))
    agency = result.scalar_one_or_none()
    invalid = HTTPException(status_code=400, detail="Invalid or expired reset code")
    if not agency or not agency.reset_code_hash or not agency.reset_code_expires_at:
        raise invalid
    if datetime.utcnow() > agency.reset_code_expires_at:
        raise invalid
    if not verify_password(code, agency.reset_code_hash):
        raise invalid

    agency.password_hash = hash_password(new_password)
    agency.reset_code_hash = None
    agency.reset_code_expires_at = None
    await db.commit()
