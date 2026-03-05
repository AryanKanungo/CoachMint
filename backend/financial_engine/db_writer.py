"""
DB Writer — saves engine output to financial_snapshots.

One row per user per day.
If the engine runs multiple times today, upsert overwrites the same row.
Conflict key: (user_id, snapshot_date)

What is stored vs what is returned live:
    STORED in DB    → aggregates Flutter needs to render history/charts
    NOT stored      → bill_guard list, goal_results list
                      (these are returned live in the API response,
                       too verbose to store per snapshot)
"""

from datetime import date
from supabase import Client
from financial_engine.variables import EngineOutput


def save_snapshot(user_id: str, output: EngineOutput, db: Client) -> None:

    row = {
        "user_id":                  user_id,
        "snapshot_date":            str(date.today()),

        # wallet
        "wallet_balance":           output.wallet_balance,

        # spending
        "upcoming_bills_total":     output.upcoming_bills_total,
        "avg_daily_expense":        output.avg_daily_expense,
        "essential_daily_expense":  output.essential_daily_expense,

        # primary outputs
        "safe_to_spend_per_day":    output.safe_to_spend_per_day,
        "survival_days":            output.survival_days,

        # resilience
        "resilience_score":         output.resilience_score,
        "resilience_label":         output.resilience_label,
        "pillar_scores":            output.pillar_scores,      # JSONB

        # income
        "income_trend":             output.income_trend,

        # flags
        "risk_flags":               output.risk_flags,         # JSONB array
    }

    (
        db.table("financial_snapshots")
        .upsert(row, on_conflict="user_id,snapshot_date")
        .execute()
    )
