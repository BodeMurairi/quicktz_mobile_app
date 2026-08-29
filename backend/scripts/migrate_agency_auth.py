"""
One-time migration for real agency authentication.

1. Adds login_email/password_hash columns to `agencies` (idempotent).
2. Rebuilds `bookings` so user_id is nullable (SQLite has no ALTER COLUMN, so this
   renames the old table, creates the new schema, copies data, drops the old one).
3. Backfills login credentials for every existing agency that doesn't have one yet
   (uses the agency's existing contact_email if set, else a synthesized placeholder),
   and prints the plaintext passwords ONCE — they're bcrypt-hashed immediately after
   and cannot be recovered from the database.

Run from backend/: python3 scripts/migrate_agency_auth.py
Safe to re-run — every step checks whether it's already been applied.
"""
import re
import secrets
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from services.auth_service import hash_password  # noqa: E402

DB_PATH = Path(__file__).resolve().parent.parent / "quicktz.db"


def slugify(name: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    return slug or "agency"


def migrate_schema(cur: sqlite3.Cursor) -> None:
    cols = {row[1] for row in cur.execute("PRAGMA table_info(agencies)")}
    if "login_email" not in cols:
        cur.execute("ALTER TABLE agencies ADD COLUMN login_email VARCHAR")
        print("  + agencies.login_email added")
    if "password_hash" not in cols:
        cur.execute("ALTER TABLE agencies ADD COLUMN password_hash VARCHAR")
        print("  + agencies.password_hash added")
    cur.execute("CREATE UNIQUE INDEX IF NOT EXISTS ix_agencies_login_email ON agencies (login_email)")

    booking_cols = list(cur.execute("PRAGMA table_info(bookings)"))
    user_id_notnull = next(c for c in booking_cols if c[1] == "user_id")[3]
    if user_id_notnull:
        print("  + rebuilding bookings table (user_id -> nullable)...")
        cur.execute("ALTER TABLE bookings RENAME TO bookings_old")
        cur.execute("""
            CREATE TABLE bookings (
                id VARCHAR NOT NULL PRIMARY KEY,
                user_id VARCHAR,
                trip_id VARCHAR NOT NULL,
                seat_number INTEGER,
                passenger_name VARCHAR NOT NULL,
                passenger_phone VARCHAR,
                total_price FLOAT NOT NULL,
                status VARCHAR,
                created_at DATETIME,
                updated_at DATETIME,
                FOREIGN KEY(user_id) REFERENCES users (id),
                FOREIGN KEY(trip_id) REFERENCES trips (id)
            )
        """)
        cur.execute("""
            INSERT INTO bookings (id, user_id, trip_id, seat_number, passenger_name,
                                   passenger_phone, total_price, status, created_at, updated_at)
            SELECT id, user_id, trip_id, seat_number, passenger_name,
                   passenger_phone, total_price, status, created_at, updated_at
            FROM bookings_old
        """)
        cur.execute("DROP TABLE bookings_old")
        print("  + bookings table rebuilt, data preserved")
    else:
        print("  ✓ bookings.user_id already nullable")


def backfill_credentials(cur: sqlite3.Cursor) -> list[tuple[str, str, str]]:
    rows = cur.execute(
        "SELECT id, name, contact_email FROM agencies WHERE login_email IS NULL"
    ).fetchall()
    issued = []
    for agency_id, name, contact_email in rows:
        login_email = contact_email or f"{slugify(name)}@quicktz.test"
        # login_email must be unique — fall back to a suffixed placeholder on collision.
        existing = cur.execute(
            "SELECT id FROM agencies WHERE login_email = ? AND id != ?", (login_email, agency_id)
        ).fetchone()
        if existing:
            login_email = f"{slugify(name)}-{agency_id[:8]}@quicktz.test"

        password = secrets.token_urlsafe(9)  # ~12 chars, URL-safe
        cur.execute(
            "UPDATE agencies SET login_email = ?, password_hash = ? WHERE id = ?",
            (login_email, hash_password(password), agency_id),
        )
        issued.append((name, login_email, password))
    return issued


def main():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    print("Migrating schema...")
    migrate_schema(cur)
    print("Backfilling agency credentials...")
    issued = backfill_credentials(cur)
    conn.commit()
    conn.close()

    if not issued:
        print("\nNo agencies needed new credentials (all already have a login_email).")
        return

    print("\n" + "=" * 78)
    print("NEW AGENCY LOGIN CREDENTIALS — save these now, they can't be recovered later")
    print("=" * 78)
    print(f"{'Agency':<28} {'Login email':<32} Password")
    print("-" * 78)
    for name, email, password in issued:
        print(f"{name:<28} {email:<32} {password}")
    print("=" * 78)


if __name__ == "__main__":
    main()
