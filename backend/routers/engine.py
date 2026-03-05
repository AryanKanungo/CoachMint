"""
Engine Router — two endpoints.

GET  /api/engine/snapshot/{user_id}
     Full run: read DB → engine → write snapshot → return to Flutter.
     Called on app open and after every categorised transaction.

POST /api/engine/simulate
     Check Before Spending — stateless, no DB write.
     Runs engine twice (before and after proposed spend) and returns delta.
"""

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from core.database              import get_db
from financial_engine.db_reader import fetch_engine_input
from financial_engine.db_writer import save_snapshot
from financial_engine.engine    import run_engine

router = APIRouter(prefix="/api/engine", tags=["engine"])


@router.get("/snapshot/{user_id}")
def get_snapshot(user_id: str, db=Depends(get_db)):
    """Full engine run. Called by Flutter on app open + after every transaction."""
    inp    = fetch_engine_input(user_id, db)
    output = run_engine(inp)
    save_snapshot(user_id, output, db)
    return output


class SimulateRequest(BaseModel):
    user_id:        str
    proposed_spend: float


@router.post("/simulate")
def simulate_spend(req: SimulateRequest, db=Depends(get_db)):
    """
    Check Before Spending. No DB write.

    Runs engine on current state, then again with CB reduced by proposed_spend.
    Returns the delta so Flutter can display the impact before committing.
    """
    inp     = fetch_engine_input(req.user_id, db)
    current = run_engine(inp)

    # deduct proposed spend from resolved balance and clear SMS balances
    # so the wallet math uses the modified figure
    modified_balance         = current.wallet_balance - req.proposed_spend
    inp.starting_balance     = modified_balance
    for txn in inp.transactions_30d:
        txn.wallet_balance_after = None

    simulated        = run_engine(inp)
    any_bill_at_risk = any(b.at_risk for b in simulated.bill_guard)

    if simulated.safe_to_spend_per_day >= 0 and not any_bill_at_risk:
        verdict = "SAFE"
    elif simulated.safe_to_spend_per_day >= 0:
        verdict = "CAUTION"
    else:
        verdict = "DANGER"

    return {
        "proposed_spend":           req.proposed_spend,
        "current_spd":              current.safe_to_spend_per_day,
        "simulated_spd":            simulated.safe_to_spend_per_day,
        "current_survival_days":    current.survival_days,
        "simulated_survival_days":  simulated.survival_days,
        "bills_still_covered":      not any_bill_at_risk,
        "resilience_impact":        round(simulated.resilience_score - current.resilience_score, 1),
        "verdict":                  verdict,
    }
