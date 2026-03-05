"""
All input/output dataclasses for the financial engine.

EngineInput  — assembled from Supabase by db_reader.py
EngineOutput — written to Supabase by db_writer.py, returned to Flutter

These mirror the Supabase schema exactly.
The engine itself only ever sees these objects — never touches the DB.
"""

from dataclasses import dataclass
from datetime import date


# ── INPUT ─────────────────────────────────────────────────────────────────────

@dataclass
class Transaction:
    """
    One row from the transactions table.
    Only columns the engine needs — nothing else pulled from DB.
    """
    type: str                          # "credit" | "debit"
    amount: float
    category_top: str                  # "needs" | "wants" | "savings" | "income" | "transfer"
    wallet_balance_after: float | None # present when the bank SMS included Avl Bal
    transaction_date: str              # ISO string e.g. "2026-03-01T10:30:00"


@dataclass
class Bill:
    """One unpaid row from the bills table."""
    name: str
    amount: float
    due_date: date
    is_recurring: bool


@dataclass
class Goal:
    """One row from the goals table."""
    name: str
    target_amount: float
    saved_amount: float
    deadline: date | None
    is_emergency_fund: bool


@dataclass
class EngineInput:
    """
    Everything the engine needs to run.
    Assembled by db_reader.py — the engine never queries the DB itself.
    """
    user_id: str

    # from user_profile
    starting_balance: float      # wallet seed from onboarding
    next_income_date: date
    expected_income: float
    income_frequency: str        # "irregular" | "weekly" | "monthly"

    # from transactions table (last 30 days)
    transactions_30d: list[Transaction]

    # from bills table (unpaid rows only)
    bills: list[Bill]

    # from goals table
    goals: list[Goal]


# ── OUTPUT ────────────────────────────────────────────────────────────────────

@dataclass
class BillGuardResult:
    """Per-bill risk assessment."""
    name: str
    amount: float
    due_date: date
    projected_balance_at_due: float    # what CB will be on that day at current ADE
    at_risk: bool                      # projected_balance < bill.amount


@dataclass
class GoalResult:
    """Per-goal progress snapshot."""
    name: str
    target: float
    saved: float
    remaining: float
    daily_surplus_needed: float        # ₹/day needed to hit goal by deadline
    days_to_goal: float                # at current surplus rate
    on_track: bool
    is_emergency_fund: bool


@dataclass
class EngineOutput:
    """
    Full output of one engine run.

    Aggregates → written to financial_snapshots by db_writer.py
    Detail lists → returned live to Flutter in the API response
                   (bill_guard, goal_results not stored in DB)
    """

    # ── wallet ────────────────────────────────────────────────────────────────
    wallet_balance: float              # CB — resolved from SMS or wallet math

    # ── spending variables ────────────────────────────────────────────────────
    upcoming_bills_total: float        # UB
    avg_daily_expense: float           # ADE  = (needs+wants debits last 30d) / 30
    essential_daily_expense: float     # EDE  = (needs-only debits last 30d) / 30
    min_reserve: float                 # 3 × EDE — always protected, never spent

    # ── primary dashboard numbers ─────────────────────────────────────────────
    safe_to_spend_per_day: float       # SPD = (CB - UB - MIN_RESERVE) / ND
    survival_days: float               # SD  = (CB - UB) / ADE

    # ── resilience ───────────────────────────────────────────────────────────
    resilience_score: float            # 0–100
    resilience_label: str              # "Strong" | "Moderate" | "Building" | "Fragile"
    pillar_scores: dict                # {p1_survival, p2_bills, p3_discipline, p4_stability, p5_emergency}

    # ── income ───────────────────────────────────────────────────────────────
    income_trend: str                  # "dip" | "stable" | "surge"
    income_cv: float                   # coefficient of variation — volatility

    # ── risk flags (consumed by the agentic layer to decide alerts) ───────────
    risk_flags: list[str]

    # ── detail (returned to Flutter, not stored in DB) ────────────────────────
    bill_guard: list[BillGuardResult]
    goal_results: list[GoalResult]
    ef_progress: float                 # 0.0 → 1.0
