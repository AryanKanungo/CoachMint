from fastapi import APIRouter, Request
from engine import execute_full_pipeline

router = APIRouter(prefix="/webhooks")

@router.post("/on-data-change")
async def handle_update(request: Request):
    payload = await request.json()
    record = payload.get('record') or payload.get('old_record')
    user_id = record.get('user_id')
    if user_id:
        from main import db
        execute_full_pipeline(user_id, db)
        return {"status": "recalculated"}
    return {"status": "ignored"}