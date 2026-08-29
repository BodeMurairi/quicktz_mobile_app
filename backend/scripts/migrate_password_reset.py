"""
One-time migration: adds password-reset columns to `users` and `agencies`.

Both are new nullable columns, so a plain ALTER TABLE ADD COLUMN is enough —
no table rebuild needed (unlike the bookings.user_id migration).

Run from backend/: python3 scripts/migrate_password_reset.py
Safe to re-run — checks PRAGMA table_info before altering.
"""
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

DB_PATH = Path(__file__).resolve().parent.parent / "quicktz.db"


def add_reset_columns(cur: sqlite3.Cursor, table: str) -> None:
    cols = {row[1] for row in cur.execute(f"PRAGMA table_info({table})")}
    if "reset_code_hash" not in cols:
        cur.execute(f"ALTER TABLE {table} ADD COLUMN reset_code_hash VARCHAR")
        print(f"  + {table}.reset_code_hash added")
    if "reset_code_expires_at" not in cols:
        cur.execute(f"ALTER TABLE {table} ADD COLUMN reset_code_expires_at DATETIME")
        print(f"  + {table}.reset_code_expires_at added")


def main():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    print("Migrating schema...")
    add_reset_columns(cur, "users")
    add_reset_columns(cur, "agencies")
    conn.commit()
    conn.close()
    print("Done.")


if __name__ == "__main__":
    main()
