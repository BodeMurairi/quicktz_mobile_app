import uvicorn

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config.settings import settings
from data.database import engine, Base
import models  # noqa: F401 — registers all ORM models with Base

from controller import auth, users, agencies, trips, bookings, tickets, notifications, agent_chat


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="QuickTZ — Bus Ticket Booking Platform API",
    lifespan=lifespan,
    redirect_slashes=False,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

PREFIX = "/api/v1"
app.include_router(auth.router, prefix=f"{PREFIX}/auth", tags=["Auth"])
app.include_router(users.router, prefix=f"{PREFIX}/users", tags=["Users"])
app.include_router(agencies.router, prefix=f"{PREFIX}/agencies", tags=["Agencies"])
app.include_router(trips.router, prefix=f"{PREFIX}/trips", tags=["Trips"])
app.include_router(bookings.router, prefix=f"{PREFIX}/bookings", tags=["Bookings"])
app.include_router(tickets.router, prefix=f"{PREFIX}/tickets", tags=["Tickets"])
app.include_router(notifications.router, prefix=f"{PREFIX}/notifications", tags=["Notifications"])
app.include_router(agent_chat.router, prefix=f"{PREFIX}/agent", tags=["AI Agent"])


@app.get("/", tags=["Health"])
async def root():
    return {"app": settings.APP_NAME, "version": settings.APP_VERSION, "status": "running"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
