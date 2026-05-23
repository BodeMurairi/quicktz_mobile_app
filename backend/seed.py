"""
Run once to populate the database with test data:
    cd backend && python3 seed.py
"""
import asyncio
import hashlib
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
            {"name": "STIF Togo",           "contact_phone": "+228 22 21 00 00", "address": "Lomé"},
            {"name": "UTB Togo",            "contact_phone": "+228 22 35 00 11", "address": "Lomé"},
            {"name": "TSITO Express",       "contact_phone": "+228 90 12 34 56", "address": "Kara"},
            {"name": "Trans Sahel Voyages", "contact_phone": "+228 91 23 45 67", "address": "Lomé"},
            {"name": "Agou Confort",        "contact_phone": "+228 93 45 67 89", "address": "Atakpamé"},
            {"name": "Savane Express",      "contact_phone": "+228 95 67 89 01", "address": "Sokodé"},
            {"name": "Dapaong Lines",       "contact_phone": "+228 97 89 01 23", "address": "Dapaong"},
            {"name": "Volta Voyages",       "contact_phone": "+228 99 01 23 45", "address": "Lomé"},
        ]
        agencies = []
        for data in agencies_data:
            a = Agency(id=str(uuid.uuid4()), is_verified=True, is_active=True, **data)
            db.add(a)
            agencies.append(a)
        await db.flush()

        # ── Routes ──────────────────────────────────────────────────────────
        # Each entry: (origin, destination, distance_km, duration_minutes, agency_index, price)
        routes_data = [
            # Major north-south corridor (N1 highway)
            ("Lomé",        "Kara",         420, 360, 0, 3500),
            ("Kara",        "Lomé",         420, 360, 0, 3500),
            ("Lomé",        "Atakpamé",     161, 150, 1, 2000),
            ("Atakpamé",    "Lomé",         161, 150, 1, 2000),
            ("Lomé",        "Sokodé",       336, 300, 2, 3000),
            ("Sokodé",      "Lomé",         336, 300, 2, 3000),
            ("Lomé",        "Dapaong",      636, 540, 3, 6000),
            ("Dapaong",     "Lomé",         636, 540, 3, 6000),
            # Mid-corridor hops
            ("Atakpamé",    "Kara",         259, 240, 4, 2500),
            ("Kara",        "Atakpamé",     259, 240, 4, 2500),
            ("Atakpamé",    "Sokodé",       175, 165, 5, 1800),
            ("Sokodé",      "Atakpamé",     175, 165, 5, 1800),
            ("Sokodé",      "Kara",         84,   80, 6, 1000),
            ("Kara",        "Sokodé",       84,   80, 6, 1000),
            ("Kara",        "Dapaong",      216, 195, 7, 2500),
            ("Dapaong",     "Kara",         216, 195, 7, 2500),
            # Coastal / southwest
            ("Lomé",        "Tsévié",       35,   35, 0, 500),
            ("Tsévié",      "Lomé",         35,   35, 0, 500),
            ("Lomé",        "Notsé",        99,   95, 1, 1200),
            ("Notsé",       "Lomé",         99,   95, 1, 1200),
            # Cross routes
            ("Lomé",        "Bassar",       395, 355, 2, 3800),
            ("Bassar",      "Lomé",         395, 355, 2, 3800),
        ]

        routes = []
        prices_map = {}
        for (origin, dest, dist, dur, ag_idx, price) in routes_data:
            r = Route(
                id=str(uuid.uuid4()),
                agency_id=agencies[ag_idx % len(agencies)].id,
                origin=origin,
                destination=dest,
                distance_km=dist,
                duration_minutes=dur,
                is_active=True,
            )
            db.add(r)
            routes.append(r)
            prices_map[r.id] = price
        await db.flush()

        # ── Trips (next 10 days, multiple departures per route per day) ──────
        departures_am = [6, 8, 10]   # morning slots
        departures_pm = [13, 16, 19] # afternoon/evening slots

        for day_offset in range(10):
            base_date = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
            trip_date = base_date + timedelta(days=day_offset)

            for route in routes:
                price = prices_map[route.id]
                # Short routes get 6 departures; longer routes get 3
                hours = departures_am + departures_pm if (route.distance_km or 0) <= 200 else departures_am

                for hour in hours:
                    dep = trip_date + timedelta(hours=hour)
                    arr = dep + timedelta(minutes=route.duration_minutes or 180)
                    tid = str(uuid.uuid4())
                    h = int(hashlib.md5(tid.encode()).hexdigest(), 16)
                    trip = Trip(
                        id=tid,
                        route_id=route.id,
                        departure_datetime=dep,
                        arrival_datetime=arr,
                        total_seats=50,
                        available_seats=50,
                        price=price,
                        bus_number=f"TG-{1000 + day_offset * 100 + hour}",
                        status="scheduled",
                        has_wifi=bool((h >> 0) & 1),
                        has_meal=bool((h >> 1) & 1),
                        has_ac=bool((h >> 2) & 1),
                        has_usb=bool((h >> 3) & 1),
                        is_active=True,
                    )
                    db.add(trip)

        await db.commit()

        route_summary = ", ".join(
            f"{o}→{d}"
            for (o, d, *_) in routes_data
        )
        print(f"✓ Seeded: {len(agencies)} agencies, {len(routes)} routes, trips for the next 10 days.")
        print(f"  Agencies: {', '.join(a.name for a in agencies)}")
        print(f"  Routes: {route_summary}")


if __name__ == "__main__":
    asyncio.run(seed())
