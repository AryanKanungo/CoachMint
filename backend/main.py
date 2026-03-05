import os
from dataclasses import asdict
from fastapi import FastAPI, HTTPException
from supabase import create_client, Client
from dotenv import load_dotenv

# Import the logic files
from engine import build_input, run_engine, upsert_snapshot
from predictor import run_prediction

# Load environment variables
load_dotenv()

app = FastAPI(title="CoachMint API")

# Initialize Supabase client
url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_KEY")
if not url or not key:
    raise ValueError("Missing Supabase credentials in .env")
db: Client = create_client(url, key)


@app.post("/test-engine/{user_id}")
def test_engine(user_id: str):
    """
    PHASE 1 ONLY: Runs the Ground Truth math and upserts the base snapshot.
    """
    try:
        engine_input = build_input(user_id, db)
        engine_output = run_engine(engine_input)
        upsert_snapshot(user_id, engine_output, db)

        return {
            "status": "success",
            "message": "Engine ran and snapshot upserted.",
            "data": asdict(engine_output) # Converts the dataclass to clean JSON
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Engine Error: {str(e)}")


@app.post("/test-predictor/{user_id}")
def test_predictor(user_id: str):
    """
    PHASE 2 ONLY: Runs time-series predictions and updates the snapshot.
    Note: You should run /test-engine first so a snapshot exists for today.
    """
    try:
        prediction_results = run_prediction(user_id, db)

        return {
            "status": "success",
            "message": "Predictor ran, predictions inserted, snapshot updated.",
            "data": prediction_results
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Predictor Error: {str(e)}")


@app.post("/run-full-pipeline/{user_id}")
def run_full_pipeline(user_id: str):
    """
    PRODUCTION ROUTE: Runs both in sequence. This is what Flutter will call.
    """
    try:
        # 1. Engine
        engine_input = build_input(user_id, db)
        engine_output = run_engine(engine_input)
        upsert_snapshot(user_id, engine_output, db)

        # 2. Predictor
        prediction_results = run_prediction(user_id, db)

        return {
            "status": "success",
            "message": "Full pipeline completed.",
            "final_survival_days": prediction_results.get("predicted_survival_days"),
            "engine_base_resilience": engine_output.resilience_score,
            "flags": prediction_results.get("risk_flags")
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Pipeline Error: {str(e)}")