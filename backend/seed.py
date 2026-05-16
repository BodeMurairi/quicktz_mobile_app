"""
Run once to populate the database with test data:
    cd backend && python3 seed.py
"""
import asyncio
import uuid
from datetime import datetime, timedelta

from data.database import AsyncSessionLocal, engine, Base
from models import Agency, Route, Trip  # registers all models


async def seed():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as db:
        # ── Agencies ────────────────────────────────────────────────────────
        agencies_data = [
            {"name": "STIF Togo",        "contact_phone": "+228 22 21 00 00", "address": "Lomé"},
            {"name": "UTB Togo",         "contact_phone": "+228 22 35 00 11", "address": "Lomé"},
            {"name": "TSITO Express",    "contact_phone": "+228 90 12 34 56", "address": "Kara"},
        ]
        agencies = []
        for data in agencies_data:
            a = Agency(id=str(uuid.uuid4()), is_verified=True, is_active=True, **data)
            db.add(a)
            agencies.append(a)
        await db.flush()

        # ── Routes ──────────────────────────────────────────────────────────
        routes_data = [
            {"origin": "Lomé",    "destination": "Kara",       "distance_km": 420, "duration_minutes": 360},
            {"origin": "Lomé",    "destination": "Atakpamé",   "distance_km": 161, "duration_minutes": 150},
            {"origin": "Lomé",    "destination": "Sokodé",     "distance_km": 336, "duration_minutes": 300},
            {"origin": "Kara",    "destination": "Lomé",       "distance_km": 420, "duration_minutes": 360},
            {"origin": "Atakpamé","destination": "Lomé",       "distance_km": 161, "duration_minutes": 150},
            {"origin": "Lomé",    "destination": "Dapaong",    "distance_km": 636, "duration_minutes": 540},
        ]
        routes = []
        for i, data in enumerate(routes_data):
            r = Route(
                id=str(uuid.uuid4()),
                agency_id=agencies[i % len(agencies)].id,
                is_active=True,
                **data,
            )
            db.add(r)
            routes.append(r)
        await db.flush()

        # ── Trips (next 7 days, multiple per day) ───────────────────────────
        prices = [3500, 2500, 3000, 3500, 2500, 6000]
        departures = [6, 8, 10, 14, 16, 18]  # hours

        for day_offset in range(7):
            base_date = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
            trip_date = base_date + timedelta(days=day_offset)

            for route, price in zip(routes, prices):
                for hour in departures[:3]:  # 3 departures per route per day
                    dep = trip_date + timedelta(hours=hour)
                    arr = dep + timedelta(minutes=route.duration_minutes or 180)
                    trip = Trip(
                        id=str(uuid.uuid4()),
                        route_id=route.id,
                        departure_datetime=dep,
                        arrival_datetime=arr,
                        total_seats=50,
                        available_seats=50,
                        price=price,
                        bus_number=f"TG-{1000 + day_offset * 10 + hour}",
                        status="scheduled",
                        is_active=True,
                    )
                    db.add(trip)

        await db.commit()
        print("✓ Seeded: 3 agencies, 6 routes, and trips for the next 7 days.")
        print("  Routes: Lomé↔Kara, Lomé↔Atakpamé, Lomé↔Sokodé, Lomé↔Dapaong")


if __name__ == "__main__":
    asyncio.run(seed())
