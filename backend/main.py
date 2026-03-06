import os
from fastapi import FastAPI, HTTPException
from supabase import create_client, Client
from dotenv import load_dotenv

# Import the modular logic
from engine import execute_full_pipeline

load_dotenv()
app = FastAPI(title="CoachMint Generalized Engine")

# Initialize Supabase client
url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_KEY")
db: Client = create_client(url, key)

@app.post("/recalculate/{user_id}")
async def sync_financials(user_id: str):
    """
    UNIVERSAL ENDPOINT: 
    Called by Supabase Triggers whenever any table (Bills, Txns, Profile) changes.
    """
    try:
        results = execute_full_pipeline(user_id, db)
        return {
            "status": "synchronized",
            "user_id": user_id,
            "resilience": results["engine"].resilience_score
        }
    except Exception as e:
        print(f"Recalculation Error for {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
def health_check():
    return {"status": "online"}