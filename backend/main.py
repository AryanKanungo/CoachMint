import os
from datetime import date, datetime, timedelta
from dotenv import load_dotenv
from fastapi import FastAPI, Request, HTTPException
from supabase import create_client, Client

from engine import EngineInput, run_engine

load_dotenv()

app = FastAPI()

# ── Supabase client ────────────────────────────────────────────────────────
def get_db() -> Client:
    return create_client(
        os.environ["SUPABASE_URL"],
        os.environ["SUPABASE_SERVICE_KEY"],
    )


# ── Webhook entry point ────────────────────────────────────────────────────
# Set this URL in Supabase Dashboard → Database Webhooks
# Tables: transactions (INSERT), bills (INSERT, UPDATE), user_profile (UPDATE), goals (INSERT, UPDATE)
# Method: POST

@app.post("/engine/recalculate")
async def recalculate(request: Request):
    payload = await request.json()

    # Supabase webhook sends: {"type": "INSERT"|"UPDATE", "table": "...", "record": {...}}
    record = payload.get("record", {})
    user_id = record.get("user_id") or record.get("id")

    if not user_id:
        return {"status": "skipped", "reason": "no user_id in record"}

    try:
        db  = get_db()
        inp = build_input(user_id, db)
        out = run_engine(inp)
        save_snapshot(out, db)
        return {"status": "ok", "user_id": user_id}
    except Exception as e:
        # Don't crash — log and return 200 so Supabase doesn't retry forever
        print(f"Engine error for {user_id}: {e}")
        return {"status": "error", "detail": str(e)}


# ── Health check ───────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {"status": "ok"}


# ── build_input — reads Supabase, returns EngineInput ─────────────────────

def build_input(user_id: str, db: Client) -> EngineInput:
    # user_profile
    profile_res = (
        db.table("user_profile")
        .select("starting_balance, next_income_date, expected_income")
        .eq("user_id", user_id)
        .single()
        .execute()
    )
    profile = profile_res.data or {}

    starting_balance = float(profile.get("starting_balance") or 0)
    expected_income  = float(profile.get("expected_income") or 0)

    next_income_date = None
    raw_date = profile.get("next_income_date")
    if raw_date:
        try:
            next_income_date = date.fromisoformat(str(raw_date)[:10])
        except Exception:
            pass

    # transactions — last 30 days
    thirty_days_ago = (datetime.utcnow() - timedelta(days=30)).isoformat()
    txn_res = (
        db.table("transactions")
        .select("amount, direction, category, timestamp")
        .eq("user_id", user_id)
        .gte("timestamp", thirty_days_ago)
        .execute()
    )
    transactions = txn_res.data or []

    # bills — unpaid only
    bill_res = (
        db.table("bills")
        .select("amount, due_date, is_paid")
        .eq("user_id", user_id)
        .eq("is_paid", False)
        .execute()
    )
    bills = bill_res.data or []

    # goals
    goal_res = (
        db.table("goals")
        .select("id, title, target_amount, saved_amount, deadline")
        .eq("user_id", user_id)
        .execute()
    )
    goals = goal_res.data or []

    return EngineInput(
        user_id          = user_id,
        starting_balance = starting_balance,
        next_income_date = next_income_date,
        expected_income  = expected_income,
        transactions     = transactions,
        bills            = bills,
        goals            = goals,
    )


# ── save_snapshot — upserts EngineOutput to financial_snapshots ───────────

def save_snapshot(out, db: Client):
    db.table("financial_snapshots").upsert(
        {
            "user_id":          out.user_id,
            "snapshot_date":    out.snapshot_date,
            "cb":               out.cb,
            "ub":               out.ub,
            "nd":               out.nd,
            "ade":              out.ade,
            "min_reserve":      out.min_reserve,
            "spd":              out.spd,
            "resilience_score": out.resilience_score,
            "survival_days":    out.survival_days,
        },
        on_conflict="user_id,snapshot_date",
    ).execute()