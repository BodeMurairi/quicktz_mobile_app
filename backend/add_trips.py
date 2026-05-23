"""
Adds scheduled trips from today through the next 60 days.
Safe to re-run — skips days that already have trips for a given route.
    cd backend && python3 add_trips.py
"""
import asyncio
import hashlib
import uuid
from datetime import datetime, timedelta, timezone

from data.database import AsyncSessionLocal, engine, Base
from models import Route, Trip
from sqlalchemy import select, and_


PRICES = {
    ("Lomé",        "Kara"):         3500,
    ("Kara",        "Lomé"):         3500,
    ("Lomé",        "Atakpamé"):     2000,
    ("Atakpamé",    "Lomé"):         2000,
    ("Lomé",        "Sokodé"):       3000,
    ("Sokodé",      "Lomé"):         3000,
    ("Lomé",        "Dapaong"):      6000,
    ("Dapaong",     "Lomé"):         6000,
    ("Atakpamé",    "Kara"):         2500,
    ("Kara",        "Atakpamé"):     2500,
    ("Atakpamé",    "Sokodé"):       1800,
    ("Sokodé",      "Atakpamé"):     1800,
    ("Sokodé",      "Kara"):         1000,
    ("Kara",        "Sokodé"):       1000,
    ("Kara",        "Dapaong"):      2500,
    ("Dapaong",     "Kara"):         2500,
    ("Lomé",        "Tsévié"):        500,
    ("Tsévié",      "Lomé"):          500,
    ("Lomé",        "Notsé"):        1200,
    ("Notsé",       "Lomé"):         1200,
    ("Lomé",        "Bassar"):       3800,
    ("Bassar",      "Lomé"):         3800,
}

# Always cover today → today + 60 days
_today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
START_DATE = _today
END_DATE   = _today + timedelta(days=60)

AM_SLOTS = [6, 8, 10]
PM_SLOTS = [13, 16, 19]


async def add_trips():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Route).where(Route.is_active == True))
        routes = result.scalars().all()

        if not routes:
            print("No routes found — run seed.py first.")
            return

        # Collect route IDs that already have trips in each target day (dedup)
        existing_result = await db.execute(
            select(Trip.route_id, Trip.departure_datetime)
            .where(Trip.departure_datetime >= START_DATE,
                   Trip.departure_datetime <= END_DATE + timedelta(days=1))
        )
        existing = {(r, d.date()) for r, d in existing_result.all()}

        trips_added = 0
        current = START_DATE
        while current <= END_DATE:
            day_label = current.strftime("%Y%m%d")
            for route in routes:
                if (route.id, current.date()) in existing:
                    continue  # already seeded this route for this day
                price = PRICES.get((route.origin, route.destination), 2000)
                hours = AM_SLOTS + PM_SLOTS if (route.distance_km or 0) <= 200 else AM_SLOTS
                for hour in hours:
                    dep_naive = datetime(current.year, current.month, current.day, hour)
                    arr_naive = dep_naive + timedelta(minutes=route.duration_minutes or 180)
                    tid = str(uuid.uuid4())
                    h = int(hashlib.md5(tid.encode()).hexdigest(), 16)
                    trip = Trip(
                        id=tid,
                        route_id=route.id,
                        departure_datetime=dep_naive,
                        arrival_datetime=arr_naive,
                        total_seats=50,
                        available_seats=50,
                        price=float(price),
                        bus_number=f"TG-{day_label[4:]}-{hour:02d}",
                        status="scheduled",
                        has_wifi=bool((h >> 0) & 1),
                        has_meal=bool((h >> 1) & 1),
                        has_ac=bool((h >> 2) & 1),
                        has_usb=bool((h >> 3) & 1),
                        is_active=True,
                    )
                    db.add(trip)
                    trips_added += 1

            current += timedelta(days=1)

        await db.commit()
        end_str = END_DATE.strftime("%Y-%m-%d")
        print(f"✓ Added {trips_added} trips through {end_str} across {len(routes)} routes.")


if __name__ == "__main__":
    asyncio.run(add_trips())
