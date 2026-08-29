from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite+aiosqlite:///./quicktz.db"
    SECRET_KEY: str = "change-this-secret-key"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    APP_NAME: str = "QuickTZ"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    GOOGLE_API_KEY: str = ""

    # Cloudflare R2 (S3-compatible object storage) — logos, receipts, invoices, documents
    R2_ACCOUNT_ID: str = ""
    R2_ACCESS_KEY_ID: str = ""
    R2_SECRET_ACCESS_KEY: str = ""
    R2_BUCKET_NAME: str = ""
    R2_JURISDICTION: str = ""  # e.g. "eu" for a jurisdiction-restricted bucket, blank for default
    R2_PUBLIC_URL: str = ""  # e.g. https://pub-xxxx.r2.dev or a custom domain, no trailing slash

    # Platform commission — a percentage (e.g. 4.0 means 4%), not a fraction.
    COMMISSION_RATE: float = 3.0

    # Publicly-reachable base URL for this API (no trailing slash, no /api/v1) —
    # used to build links (e.g. the ticket PDF) that go into emails and chat
    # messages, which must resolve from the recipient's own device, not just
    # whichever host the caller happened to use.
    PUBLIC_API_BASE_URL: str = "http://192.168.1.77:8000"

    # SMTP — used to email ticket PDFs to riders. Sending is disabled (503) until
    # all of SMTP_HOST/SMTP_USER/SMTP_PASSWORD are set.
    SMTP_HOST: str = ""
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM_EMAIL: str = ""

    model_config = {"env_file": ".env", "extra": "ignore"}


def get_settings() -> Settings:
    """
    Builds a fresh Settings instance straight from .env on every call — unlike the
    `settings` singleton below, this picks up newly-added/rotated values (e.g. R2
    keys) without needing a process restart. Use this for config that's reasonably
    likely to change while the server is running; use `settings` for things like
    DATABASE_URL that only make sense fixed at startup.
    """
    return Settings()


settings = get_settings()
