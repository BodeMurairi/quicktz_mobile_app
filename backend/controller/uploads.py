from fastapi import APIRouter, UploadFile, File, Form

from services.storage_service import upload_file

router = APIRouter()


@router.post("")
async def upload(file: UploadFile = File(...), folder: str = Form("documents")):
    url = await upload_file(file, folder)
    return {"url": url}
