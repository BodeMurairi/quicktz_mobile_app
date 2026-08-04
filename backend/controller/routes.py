from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from data.database import get_db
from schemas.route import RouteSimpleResponse, RouteCreate, RouteUpdate
from services.route_service import create_route, get_route, update_route, delete_route

router = APIRouter()


@router.post("", response_model=RouteSimpleResponse, status_code=201)
async def create_new_route(data: RouteCreate, db: AsyncSession = Depends(get_db)):
    return await create_route(db, data)


@router.get("/{route_id}", response_model=RouteSimpleResponse)
async def get_route_detail(route_id: str, db: AsyncSession = Depends(get_db)):
    return await get_route(db, route_id)


@router.patch("/{route_id}", response_model=RouteSimpleResponse)
async def update_existing_route(route_id: str, data: RouteUpdate, db: AsyncSession = Depends(get_db)):
    return await update_route(db, route_id, data)


@router.delete("/{route_id}", status_code=204)
async def delete_existing_route(route_id: str, db: AsyncSession = Depends(get_db)):
    await delete_route(db, route_id)
