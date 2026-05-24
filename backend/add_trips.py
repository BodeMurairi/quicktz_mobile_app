"""
Bulk trip seeder — 2026-05-24 through 2026-07-24 (~3 500 trips).
Safe to re-run: skips (route, day) pairs that already have trips.
    cd backend && python3 add_trips.py
"""
import asyncio
import hashlib
import uuid
from datetime import date, datetime, timedelta

from sqlalchemy import select

from data.database import AsyncSessionLocal, engine, Base
from models import Route, Trip  # noqa: F401  registers all models

# ── Date window ────────────────────────────────────────────────────────────────
START = date(2026, 5, 24)
END   = date(2026, 7, 24)

# ── Reference prices per route pair ───────────────────────────────────────────
PRICES: dict[tuple[str, str], int] = {
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
    # Extra inter-city routes for variety
    ("Lomé",        "Bafilo"):       3800,
    ("Bafilo",      "Lomé"):         3800,
    ("Lomé",        "Niamtougou"):   4000,
    ("Niamtougou",  "Lomé"):         4000,
    ("Lomé",        "Badou"):        2800,
    ("Badou",       "Lomé"):         2800,
    ("Lomé",        "Aného"):         600,
    ("Aného",       "Lomé"):          600,
    ("Lomé",        "Vogan"):         800,
    ("Vogan",       "Lomé"):          800,
    ("Lomé",        "Tabligbo"):     1500,
    ("Tabligbo",    "Lomé"):         1500,
    ("Kara",        "Niamtougou"):   1000,
    ("Niamtougou",  "Kara"):         1000,
    ("Sokodé",      "Dapaong"):      3000,
    ("Dapaong",     "Sokodé"):       3000,
    ("Atakpamé",    "Notsé"):         800,
    ("Notsé",       "Atakpamé"):      800,
}

# Departure-hour slots: short routes get more frequency
SHORT_SLOTS  = [6, 9, 12, 16, 19]    # ≤ 200 km — 5 slots / day
MEDIUM_SLOTS = [6, 10, 15, 19]       # 201–400 km — 4 slots / day
LONG_SLOTS   = [5, 11, 17]           # > 400 km — 3 slots / day


def _slots(distance_km: float) -> list[int]:
    if distance_km <= 200:
        return SHORT_SLOTS
    if distance_km <= 400:
        return MEDIUM_SLOTS
    return LONG_SLOTS


def _amenities(tid: str, distance_km: float) -> dict[str, bool]:
    """Deterministic amenity flags based on trip UUID hash."""
    h = int(hashlib.md5(tid.encode()).hexdigest(), 16)
    is_long = distance_km > 300
    return {
        "has_ac":   (h % 100) < 68,                         # ~68 %
        "has_usb":  ((h >> 8)  % 100) < 52,                 # ~52 %
        "has_wifi": ((h >> 16) % 100) < 38,                 # ~38 %
        "has_meal": ((h >> 24) % 100) < (30 if is_long else 12),  # more on long trips
    }


def _price(base: int, tid: str) -> float:
    """Vary price ±12 % in 100-XOF steps."""
    h = int(hashlib.md5((tid + "price").encode()).hexdigest(), 16)
    factor = 0.88 + (h % 25) / 100          # 0.88 … 1.12
    return float(round(base * factor / 100) * 100)


async def add_trips() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as db:
        # Load all active routes
        rows = await db.execute(select(Route).where(Route.is_active == True))
        routes = rows.scalars().all()

        if not routes:
            print("❌  No routes found — run seed.py first.")
            return

        # Build set of (route_id, day) pairs that already have trips
        win_start = datetime(START.year, START.month, START.day)
        win_end   = datetime(END.year,   END.month,   END.day, 23, 59, 59)
        existing_rows = await db.execute(
            select(Trip.route_id, Trip.departure_datetime).where(
                Trip.departure_datetime >= win_start,
                Trip.departure_datetime <= win_end,
            )
        )
        existing: set[tuple[str, date]] = {
            (r, dt.date()) for r, dt in existing_rows.all()
        }

        total = 0
        current = START
        while current <= END:
            for route in routes:
                if (route.id, current) in existing:
                    continue  # already seeded

                base_price = PRICES.get((route.origin, route.destination), 2000)
                dist = route.distance_km or 100
                slots = _slots(dist)

                for hour in slots:
                    dep = datetime(current.year, current.month, current.day, hour)
                    arr = dep + timedelta(minutes=route.duration_minutes or 180)
                    tid = str(uuid.uuid4())
                    amenities = _amenities(tid, dist)

                    db.add(Trip(
                        id=tid,
                        route_id=route.id,
                        departure_datetime=dep,
                        arrival_datetime=arr,
                        total_seats=50,
                        available_seats=50,
                        price=_price(base_price, tid),
                        bus_number=f"TG-{current.strftime('%m%d')}-{hour:02d}",
                        status="scheduled",
                        is_active=True,
                        **amenities,
                    ))
                    total += 1

            current += timedelta(days=1)

            # Flush every 7 days to keep memory usage low
            if (current - START).days % 7 == 0:
                await db.flush()
                print(f"  … flushed through {current - timedelta(days=1)}  ({total} trips so far)")

        await db.commit()
        print(f"\n✅  Done — inserted {total} trips across {len(routes)} routes "
              f"({START} → {END}).")


if __name__ == "__main__":
    asyncio.run(add_trips())
