"""
DB Reader — fetches everything the engine needs from Supabase.
Returns a clean EngineInput. Engine never calls this directly.

Tables queried:
    user_profile    → starting_balance, next_income_date, expected_income, income_frequency
    transactions    → last 30 days, only columns engine uses
    bills           → unpaid rows only (is_paid = false)
    goals           → all active goals for the user
"""

from datetime import date, timedelta
from supabase import Client
from financial_engine.variables import EngineInput, Transaction, Bill, Goal


def fetch_engine_input(user_id: str, db: Client) -> EngineInput:

    # ── user_profile ──────────────────────────────────────────────────────────
    profile = (
        db.table("user_profile")
        .select("starting_balance, next_income_date, expected_income, income_frequency")
        .eq("user_id", user_id)
        .single()
        .execute()
    ).data

    # ── transactions — last 30 days ───────────────────────────────────────────
    since = str(date.today() - timedelta(days=30))

    txn_rows = (
        db.table("transactions")
        .select("type, amount, category_top, wallet_balance_after, transaction_date")
        .eq("user_id", user_id)
        .gte("transaction_date", since)
        .order("transaction_date", desc=True)
        .execute()
    ).data

    transactions = [
        Transaction(
            type                 = r["type"],
            amount               = float(r["amount"]),
            category_top         = r["category_top"] or "wants",
            wallet_balance_after = (
                float(r["wallet_balance_after"])
                if r.get("wallet_balance_after") is not None
                else None
            ),
            transaction_date     = r["transaction_date"],
        )
        for r in txn_rows
    ]

    # ── bills — unpaid only ───────────────────────────────────────────────────
    bill_rows = (
        db.table("bills")
        .select("name, amount, due_date, is_recurring")
        .eq("user_id", user_id)
        .eq("is_paid", False)
        .execute()
    ).data

    bills = [
        Bill(
            name         = r["name"],
            amount       = float(r["amount"]),
            due_date     = date.fromisoformat(r["due_date"]),
            is_recurring = r["is_recurring"],
        )
        for r in bill_rows
    ]

    # ── goals ─────────────────────────────────────────────────────────────────
    goal_rows = (
        db.table("goals")
        .select("name, target_amount, saved_amount, deadline, is_emergency_fund")
        .eq("user_id", user_id)
        .execute()
    ).data

    goals = [
        Goal(
            name              = r["name"],
            target_amount     = float(r["target_amount"]),
            saved_amount      = float(r["saved_amount"]),
            deadline          = date.fromisoformat(r["deadline"]) if r.get("deadline") else None,
            is_emergency_fund = r["is_emergency_fund"],
        )
        for r in goal_rows
    ]

    return EngineInput(
        user_id          = user_id,
        starting_balance = float(profile["starting_balance"]),
        next_income_date = date.fromisoformat(profile["next_income_date"]),
        expected_income  = float(profile["expected_income"]),
        income_frequency = profile["income_frequency"],
        transactions_30d = transactions,
        bills            = bills,
        goals            = goals,
    )
