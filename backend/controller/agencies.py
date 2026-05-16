from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from data.database import get_db
from schemas.agency import AgencyResponse, AgencyCreate
from services.agency_service import list_agencies, get_agency, create_agency

router = APIRouter()


@router.get("", response_model=List[AgencyResponse])
async def get_agencies(db: AsyncSession = Depends(get_db)):
    return await list_agencies(db)


@router.get("/{agency_id}", response_model=AgencyResponse)
async def get_agency_detail(agency_id: str, db: AsyncSession = Depends(get_db)):
    return await get_agency(db, agency_id)


@router.post("", response_model=AgencyResponse, status_code=201)
async def create_new_agency(data: AgencyCreate, db: AsyncSession = Depends(get_db)):
    return await create_agency(db, data)
