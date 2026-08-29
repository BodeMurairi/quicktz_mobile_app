import secrets
import uuid
import bcrypt
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from fastapi import HTTPException, status

from models.user import User
from config.settings import settings

RESET_CODE_EXPIRE_MINUTES = 15


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def create_access_token(user_id: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode(
        {"sub": user_id, "exp": expire, "type": "access"},
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )


def create_refresh_token(user_id: str) -> str:
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    return jwt.encode(
        {"sub": user_id, "exp": expire, "type": "refresh"},
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )


def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")


async def register_user(db: AsyncSession, full_name: str, password: str,
                        email: Optional[str] = None, phone_number: Optional[str] = None) -> User:
    if email:
        existing = await db.execute(select(User).where(User.email == email))
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Email already registered")
    if phone_number:
        existing = await db.execute(select(User).where(User.phone_number == phone_number))
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Phone number already registered")

    user = User(
        id=str(uuid.uuid4()),
        full_name=full_name,
        email=email,
        phone_number=phone_number,
        password_hash=hash_password(password),
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def authenticate_user(db: AsyncSession, identifier: str, password: str) -> User:
    result = await db.execute(
        select(User).where(or_(User.email == identifier, User.phone_number == identifier))
    )
    user = result.scalar_one_or_none()
    if not user or not verify_password(password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account disabled")
    return user


async def get_user_by_id(db: AsyncSession, user_id: str) -> User:
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


async def request_password_reset(db: AsyncSession, email: str) -> None:
    """Silently no-ops if the email isn't registered, so callers can't use this
    to probe which emails exist in the system."""
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()
    if not user:
        return

    code = f"{secrets.randbelow(1_000_000):06d}"
    user.reset_code_hash = hash_password(code)
    user.reset_code_expires_at = datetime.utcnow() + timedelta(minutes=RESET_CODE_EXPIRE_MINUTES)
    await db.commit()

    from services.email_service import send_password_reset_email
    send_password_reset_email(email, user.full_name, code)


async def reset_password(db: AsyncSession, email: str, code: str, new_password: str) -> None:
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()
    invalid = HTTPException(status_code=400, detail="Invalid or expired reset code")
    if not user or not user.reset_code_hash or not user.reset_code_expires_at:
        raise invalid
    if datetime.utcnow() > user.reset_code_expires_at:
        raise invalid
    if not verify_password(code, user.reset_code_hash):
        raise invalid

    user.password_hash = hash_password(new_password)
    user.reset_code_hash = None
    user.reset_code_expires_at = None
    await db.commit()
