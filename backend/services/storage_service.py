import uuid
import boto3
from botocore.client import Config
from fastapi import UploadFile, HTTPException

from config.settings import get_settings

# Buckets are organized by folder so unrelated uploads (agency branding vs.
# financial documents vs. rider-submitted files) stay easy to browse/audit.
ALLOWED_FOLDERS = {"logos", "gallery", "receipts", "invoices", "documents", "attachments"}


def _client(settings):
    if not (settings.R2_ACCOUNT_ID and settings.R2_ACCESS_KEY_ID
            and settings.R2_SECRET_ACCESS_KEY and settings.R2_BUCKET_NAME):
        raise HTTPException(status_code=503, detail="File storage is not configured on this server.")
    jurisdiction = f".{settings.R2_JURISDICTION}" if settings.R2_JURISDICTION else ""
    return boto3.client(
        "s3",
        endpoint_url=f"https://{settings.R2_ACCOUNT_ID}{jurisdiction}.r2.cloudflarestorage.com",
        aws_access_key_id=settings.R2_ACCESS_KEY_ID,
        aws_secret_access_key=settings.R2_SECRET_ACCESS_KEY,
        config=Config(signature_version="s3v4"),
        region_name="auto",
    )


async def upload_file(file: UploadFile, folder: str) -> str:
    if folder not in ALLOWED_FOLDERS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid folder. Must be one of: {', '.join(sorted(ALLOWED_FOLDERS))}",
        )

    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")

    ext = file.filename.rsplit(".", 1)[-1].lower() if file.filename and "." in file.filename else "bin"
    key = f"{folder}/{uuid.uuid4()}.{ext}"

    # Read fresh from .env each call — R2 keys can be added/rotated without a restart.
    settings = get_settings()
    client = _client(settings)
    client.put_object(
        Bucket=settings.R2_BUCKET_NAME,
        Key=key,
        Body=contents,
        ContentType=file.content_type or "application/octet-stream",
    )

    return f"{settings.R2_PUBLIC_URL.rstrip('/')}/{key}"
