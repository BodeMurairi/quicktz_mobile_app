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
