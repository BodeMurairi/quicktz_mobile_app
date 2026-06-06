"""
Seed script — agencies
Extracted from quicktz.db on 2026-06-06.

Usage:
    python data/seed_agencies.py
    python data/seed_agencies.py --db sqlite:///./new_quicktz.db
    python data/seed_agencies.py --db postgresql+psycopg2://user:pass@host/dbname
"""

import argparse
from datetime import datetime
from sqlalchemy import (
    create_engine, Column, String, Boolean, DateTime, Text, MetaData, Table, inspect
)

# ── Data extracted from quicktz.db ────────────────────────────────────────────

AGENCIES = [
    {
        "id": "69274a79-3c07-45d8-a73b-7550a4d64a85",
        "name": "STIF Togo",
        "description": None,
        "logo_url": None,
        "contact_email": None,
        "contact_phone": "+228 22 21 00 00",
        "address": "Lomé",
        "is_verified": True,
        "is_active": True,
        "created_at": datetime(2026, 5, 16, 18, 35, 12, 158848),
    },
    {
        "id": "418befde-cec5-41fd-ab1c-c003153c12a9",
        "name": "UTB Togo",
        "description": None,
        "logo_url": None,
        "contact_email": None,
        "contact_phone": "+228 22 35 00 11",
        "address": "Lomé",
        "is_verified": True,
        "is_active": True,
        "created_at": datetime(2026, 5, 16, 18, 35, 12, 158857),
    },
    {
        "id": "b549d5e3-2d02-4498-8490-d96bf4389591",
        "name": "TSITO Express",
        "description": None,
        "logo_url": None,
        "contact_email": None,
        "contact_phone": "+228 90 12 34 56",
        "address": "Kara",
        "is_verified": True,
        "is_active": True,
        "created_at": datetime(2026, 5, 16, 18, 35, 12, 158862),
    },
    {
        "id": "a9d6a680-f04a-4bf2-93a9-0e1efb1838b8",
        "name": "Trans Sahel Voyages",
        "description": None,
        "logo_url": None,
        "contact_email": None,
        "contact_phone": "+228 91 23 45 67",
        "address": "Lomé",
        "is_verified": True,
        "is_active": True,
        "created_at": datetime(2026, 5, 16, 18, 35, 12, 158864),
    },
    {
        "id": "fc5c3849-660d-4fbb-9f80-c28ce83870ea",
        "name": "Agou Confort",
        "description": None,
        "logo_url": None,
        "contact_email": None,
        "contact_phone": "+228 93 45 67 89",
        "address": "Atakpamé",
        "is_verified": True,
        "is_active": True,
        "created_at": datetime(2026, 5, 16, 18, 35, 12, 158865),
    },
    {
        "id": "2f3eef98-b58e-4df6-8d5e-f8165c5ca00a",
        "name": "Savane Express",
        "description": None,
        "logo_url": None,
        "contact_email": None,
        "contact_phone": "+228 95 67 89 01",
        "address": "Sokodé",
        "is_verified": True,
        "is_active": True,
        "created_at": datetime(2026, 5, 16, 18, 35, 12, 158866),
    },
    {
        "id": "e3e73781-a50d-4eca-9bbd-5ed261f5bf76",
        "name": "Dapaong Lines",
        "description": None,
        "logo_url": None,
        "contact_email": None,
        "contact_phone": "+228 97 89 01 23",
        "address": "Dapaong",
        "is_verified": True,
        "is_active": True,
        "created_at": datetime(2026, 5, 16, 18, 35, 12, 158868),
    },
    {
        "id": "611d00bf-b0b0-4c22-8a2c-fa1d263b02fe",
        "name": "Volta Voyages",
        "description": None,
        "logo_url": None,
        "contact_email": None,
        "contact_phone": "+228 99 01 23 45",
        "address": "Lomé",
        "is_verified": True,
        "is_active": True,
        "created_at": datetime(2026, 5, 16, 18, 35, 12, 158869),
    },
    {
        "id": "361a4c61-72d8-49eb-a531-258f33e97888",
        "name": "My agency",
        "description": "Trip agency",
        "logo_url": None,
        "contact_email": "bodemurairi2@gmail.com",
        "contact_phone": "+250795020998",
        "address": "KG 11 AV 1218",
        "is_verified": False,
        "is_active": True,
        "created_at": datetime(2026, 6, 6, 8, 57, 11, 420443),
    },
]

# ── Schema ────────────────────────────────────────────────────────────────────

def get_agencies_table(metadata: MetaData) -> Table:
    return Table(
        "agencies",
        metadata,
        Column("id",            String,  primary_key=True),
        Column("name",          String,  nullable=False),
        Column("description",   Text,    nullable=True),
        Column("logo_url",      String,  nullable=True),
        Column("contact_email", String,  nullable=True),
        Column("contact_phone", String,  nullable=True),
        Column("address",       String,  nullable=True),
        Column("is_verified",   Boolean, default=False),
        Column("is_active",     Boolean, default=True),
        Column("created_at",    DateTime),
    )

# ── Runner ────────────────────────────────────────────────────────────────────

def seed(db_url: str) -> None:
    engine = create_engine(db_url, echo=False)
    metadata = MetaData()
    agencies_table = get_agencies_table(metadata)

    # Create the table if it doesn't exist yet
    metadata.create_all(engine)

    inserted = 0
    skipped = 0

    with engine.begin() as conn:
        existing_ids = {
            row[0]
            for row in conn.execute(agencies_table.select().with_only_columns(agencies_table.c.id))
        }

        for agency in AGENCIES:
            if agency["id"] in existing_ids:
                print(f"  skip  {agency['name']} (already exists)")
                skipped += 1
            else:
                conn.execute(agencies_table.insert().values(**agency))
                print(f"  insert {agency['name']}")
                inserted += 1

    print(f"\nDone — {inserted} inserted, {skipped} skipped.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Seed agencies into a target database")
    parser.add_argument(
        "--db",
        default="sqlite:///./quicktz.db",
        help="SQLAlchemy database URL (default: sqlite:///./quicktz.db)",
    )
    args = parser.parse_args()
    print(f"Seeding agencies → {args.db}\n")
    seed(args.db)
