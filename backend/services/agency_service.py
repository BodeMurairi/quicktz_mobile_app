from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException

from models.agency import Agency
from models.route import Route
from schemas.agency import AgencyUpdate


async def list_agencies(db: AsyncSession) -> List[Agency]:
    result = await db.execute(select(Agency).where(Agency.is_active == True))
    return list(result.scalars().all())


async def get_agency(db: AsyncSession, agency_id: str) -> Agency:
    result = await db.execute(select(Agency).where(Agency.id == agency_id))
    agency = result.scalar_one_or_none()
    if not agency:
        raise HTTPException(status_code=404, detail="Agency not found")
    return agency


async def get_agency_routes(db: AsyncSession, agency_id: str) -> list[Route]:
    # Includes inactive routes — the agency dashboard needs to list and reactivate them.
    result = await db.execute(
        select(Route).where(Route.agency_id == agency_id)
    )
    return list(result.scalars().all())


async def update_agency(db: AsyncSession, agency_id: str, data: AgencyUpdate) -> Agency:
    agency = await get_agency(db, agency_id)
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(agency, field, value)
    await db.commit()
    await db.refresh(agency)
    return agency
