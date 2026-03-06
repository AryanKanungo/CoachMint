import os
from fastapi import FastAPI, HTTPException
from supabase import create_client, Client
from dotenv import load_dotenv
from engine import execute_full_pipeline
import webhooks

load_dotenv()
app = FastAPI(title="CoachMint API")

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_KEY")
db: Client = create_client(url, key)

app.include_router(webhooks.router)

@app.post("/run-full-pipeline/{user_id}")
def run_pipeline(user_id: str):
    """Manual trigger."""
    try:
        execute_full_pipeline(user_id, db)
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))