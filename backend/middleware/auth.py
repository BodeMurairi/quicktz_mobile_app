from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from data.database import get_db
from services.auth_service import decode_token, get_user_by_id
from services.agency_auth_service import get_agency_by_id
from models.user import User
from models.agency import Agency

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    payload = decode_token(credentials.credentials)
    if payload.get("type") != "access":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")
    return await get_user_by_id(db, payload["sub"])


async def get_premium_user(current_user: User = Depends(get_current_user)) -> User:
    if not current_user.is_premium:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Premium subscription required")
    return current_user


async def get_current_agency(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> Agency:
    """Agency-side counterpart of get_current_user — a fully separate token type
    (agency_access), so a rider token can never authenticate as an agency and
    vice versa, even though both are signed with the same SECRET_KEY."""
    payload = decode_token(credentials.credentials)
    if payload.get("type") != "agency_access":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")
    return await get_agency_by_id(db, payload["sub"])


def require_owns_agency(current_agency: Agency, agency_id: str) -> None:
    """Call after resolving both the token's agency and a path/body-supplied
    agency_id — 403s unless they match. Use whenever an endpoint still names an
    agency_id explicitly (e.g. in the URL) for readability/routing, so a stolen
    or mismatched id can't be used to act on a different agency's data."""
    if current_agency.id != agency_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this agency's resources",
        )
