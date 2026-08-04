import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException

from models.route import Route
from schemas.route import RouteCreate, RouteUpdate


async def create_route(db: AsyncSession, data: RouteCreate) -> Route:
    route = Route(id=str(uuid.uuid4()), **data.model_dump())
    db.add(route)
    await db.commit()
    await db.refresh(route)
    return route


async def get_route(db: AsyncSession, route_id: str) -> Route:
    route = await db.get(Route, route_id)
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    return route


async def update_route(db: AsyncSession, route_id: str, data: RouteUpdate) -> Route:
    route = await get_route(db, route_id)
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(route, field, value)
    await db.commit()
    await db.refresh(route)
    return route


async def delete_route(db: AsyncSession, route_id: str) -> None:
    route = await get_route(db, route_id)
    await db.delete(route)
    await db.commit()
