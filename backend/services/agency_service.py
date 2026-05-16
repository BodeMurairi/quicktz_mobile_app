import uuid
from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException

from models.agency import Agency
from schemas.agency import AgencyCreate


async def list_agencies(db: AsyncSession) -> List[Agency]:
    result = await db.execute(select(Agency).where(Agency.is_active == True))
    return list(result.scalars().all())


async def get_agency(db: AsyncSession, agency_id: str) -> Agency:
    result = await db.execute(select(Agency).where(Agency.id == agency_id))
    agency = result.scalar_one_or_none()
    if not agency:
        raise HTTPException(status_code=404, detail="Agency not found")
    return agency


async def create_agency(db: AsyncSession, data: AgencyCreate) -> Agency:
    agency = Agency(id=str(uuid.uuid4()), **data.model_dump())
    db.add(agency)
    await db.commit()
    await db.refresh(agency)
    return agency
