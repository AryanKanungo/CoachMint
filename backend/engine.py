"""
financial_engine/engine.py
CoachMint — Ground Truth Engine

Contract:
  build_input(user_id, db)  → EngineInput     (DB reads happen HERE)
  run_engine(inp)           → EngineOutput    (pure Python math, zero I/O)
  upsert_snapshot(user_id, output, db)        (DB write happens HERE)

The router in main.py calls these three in order.
"""

from __future__ import annotations

import statistics
from dataclasses import dataclass, field
from datetime import date, timedelta
from typing import Optional


# ── Dataclasses ───────────────────────────────────────────────────────────────

@dataclass
class BillGuardResult:
    bill_id: str
    name: str
    amount: float
    due_date: str
    projected_balance_at_due: float
    at_risk: bool
    shortfall: float


@dataclass
class GoalResult:
    goal_id: str
    title: str
    target_amount: float
    saved_amount: float
    days_to_goal: float       # 999.0 if no surplus
    on_track: bool
    daily_needed: float


@dataclass
class EngineInput:
    user_id: str
    starting_balance: float
    next_income_date: date
    expected_income: float
    transactions: list        # last 30 days — for ADE / income trend / discipline
    all_transactions: list    # all time — for CB derivation
    bills: list               # unpaid only
    goals: list
    today: date = field(default_factory=date.today)


@dataclass
class EngineOutput:
    cb: float
    ub: float
    ade: float
    ede: float
    min_reserve: float
    spd: float
    sd: float                 # survival_days in DB
    nd: int
    resilience_score: float
    resilience_label: str
    pillar_scores: dict       # {p1, p2, p3, p4, p5}
    income_trend: str         # "dip" | "stable" | "surge"
    income_cv: float
    ef_progress: float
    risk_flags: list[str]
    bill_guard: list[BillGuardResult]   # returned live; NOT stored in DB
    goal_results: list[GoalResult]      # returned live; NOT stored in DB


# ── DB layer ──────────────────────────────────────────────────────────────────

def build_input(user_id: str, db) -> EngineInput:
    """Fetch all data needed by the engine from Supabase. Only I/O in the engine layer."""
    today = date.today()
    thirty_days_ago = (today - timedelta(days=30)).isoformat()

    profile = (
        db.table("user_profile")
        .select("*")
        .eq("user_id", user_id)
        .single()
        .execute()
        .data
    )

    # Last 30 days — for ADE, income trend, spending discipline
    transactions_30d = (
        db.table("transactions")
        .select("*")
        .eq("user_id", user_id)
        .gte("timestamp", thirty_days_ago)
        .execute()
        .data
    ) or []

    # All time — for CB derivation (starting_balance + credits - debits)
    all_transactions = (
        db.table("transactions")
        .select("txn_id, amount, direction")
        .eq("user_id", user_id)
        .execute()
        .data
    ) or []

    bills = (
        db.table("bills")
        .select("*")
        .eq("user_id", user_id)
        .eq("is_paid", False)
        .execute()
        .data
    ) or []

    goals = (
        db.table("goals")
        .select("*")
        .eq("user_id", user_id)
        .execute()
        .data
    ) or []

    # Parse next_income_date — fall back to 30 days out if unset
    raw_nid = profile.get("next_income_date") if profile else None
    next_income_date = (
        date.fromisoformat(raw_nid) if raw_nid else today + timedelta(days=30)
    )

    return EngineInput(
        user_id=user_id,
        starting_balance=float((profile or {}).get("starting_balance") or 0),
        next_income_date=next_income_date,
        expected_income=float((profile or {}).get("expected_income") or 0),
        transactions=transactions_30d,
        all_transactions=all_transactions,
        bills=bills,
        goals=goals,
        today=today,
    )


def upsert_snapshot(user_id: str, output: EngineOutput, db) -> None:
    """Write today's engine result into financial_snapshots. Upserts on (user_id, snapshot_date)."""
    db.table("financial_snapshots").upsert(
        {
            "user_id": user_id,
            "snapshot_date": date.today().isoformat(),
            "cb": output.cb,
            "ub": output.ub,
            "nd": output.nd,
            "ade": output.ade,
            "min_reserve": output.min_reserve,
            "spd": output.spd,
            "resilience_score": int(output.resilience_score),
            "survival_days": output.sd,
            "income_trend": output.income_trend,
            "risk_flags": output.risk_flags,
            "pillar_scores": output.pillar_scores,
        },
        on_conflict="user_id,snapshot_date",
    ).execute()


# ── Pure math engine — ZERO I/O below this line ───────────────────────────────

def run_engine(inp: EngineInput) -> EngineOutput:
    """
    Pure Python math. No DB calls, no API calls.
    All inputs come from EngineInput; all outputs go into EngineOutput.
    """
    today = inp.today

    # ── CB (Current Balance) ──────────────────────────────────────────────────
    # Priority: starting_balance + Σ(credits) - Σ(debits) across all transactions.
    # When SMS parsing adds wallet_balance_after, update build_input() to prefer that.
    total_credits = sum(
        float(t["amount"])
        for t in inp.all_transactions
        if t.get("direction") == "credit"
    )
    total_debits = sum(
        float(t["amount"])
        for t in inp.all_transactions
        if t.get("direction") == "debit"
    )
    cb = inp.starting_balance + total_credits - total_debits

    # ── UB (Unpaid Bills due on or before next income) ────────────────────────
    ub = sum(
        float(b["amount"])
        for b in inp.bills
        if date.fromisoformat(b["due_date"]) <= inp.next_income_date
    )

    # ── ND (Days to next income — minimum 1 to prevent division by zero) ──────
    nd = max(1, (inp.next_income_date - today).days)

    # ── ADE (Avg Daily Expense: NEEDS + WANTS, last 30 days) ─────────────────
    expense_30d = sum(
        float(t["amount"])
        for t in inp.transactions
        if t.get("direction") == "debit"
        and t.get("category") in ("NEEDS", "WANTS")
    )
    ade = max(expense_30d / 30, 1.0)   # floor at ₹1 to prevent division by zero

    # ── EDE (Essential Daily Expense: NEEDS only, last 30 days) ──────────────
    essential_30d = sum(
        float(t["amount"])
        for t in inp.transactions
        if t.get("direction") == "debit"
        and t.get("category") == "NEEDS"
    )
    ede = max(essential_30d / 30, 1.0)

    # ── Derived core metrics ──────────────────────────────────────────────────
    min_reserve = 3 * ede
    asb = cb - ub - min_reserve
    spd = asb / nd
    sd = (cb - ub) / ade

    # ── Bill Guard (per-bill risk projection) ────────────────────────────────
    bill_guard: list[BillGuardResult] = []
    for bill in inp.bills:
        due = date.fromisoformat(bill["due_date"])
        days_until_due = max(0, (due - today).days)
        # Deduct all other bills whose due dates fall on or before this bill's due date
        other_bills_sum = sum(
            float(b["amount"])
            for b in inp.bills
            if b["id"] != bill["id"]
            and date.fromisoformat(b["due_date"]) <= due
        )
        projected = cb - (ade * days_until_due) - other_bills_sum
        bill_amount = float(bill["amount"])
        at_risk = projected < bill_amount
        shortfall = round(max(0.0, bill_amount - projected), 2)

        bill_guard.append(BillGuardResult(
            bill_id=bill["id"],
            name=bill["name"],
            amount=bill_amount,
            due_date=bill["due_date"],
            projected_balance_at_due=round(projected, 2),
            at_risk=at_risk,
            shortfall=shortfall,
        ))

    # ── Income Trend (weekly income credits — last 4 weeks) ──────────────────
    # wi[0] = oldest week, wi[3] = most recent week
    wi = [0.0, 0.0, 0.0, 0.0]
    for t in inp.transactions:
        if t.get("direction") == "credit" and t.get("category") == "INCOME":
            txn_date = date.fromisoformat(t["timestamp"][:10])
            days_ago = (today - txn_date).days
            week_idx = days_ago // 7
            if 0 <= week_idx < 4:
                wi[3 - week_idx] += float(t["amount"])

    mean_wi = sum(wi) / 4
    if mean_wi == 0:
        income_trend = "stable"
        income_cv = 0.0
    else:
        if wi[3] < 0.70 * mean_wi:
            income_trend = "dip"
        elif wi[3] > 1.30 * mean_wi:
            income_trend = "surge"
        else:
            income_trend = "stable"
        try:
            income_cv = statistics.stdev(wi) / mean_wi
        except statistics.StatisticsError:
            income_cv = 0.0

    # ── Emergency Fund ────────────────────────────────────────────────────────
    ef_target = 3 * ade
    ef_saved = max(0.0, cb - ub - ade)
    ef_progress = min(1.0, ef_saved / ef_target) if ef_target > 0 else 0.0

    # ── Spending Discipline — days within SPD in last 7 days (for P3) ────────
    last_7_iso = {(today - timedelta(days=i)).isoformat() for i in range(7)}
    days_within_spd = 0
    for day_str in last_7_iso:
        day_spend = sum(
            float(t["amount"])
            for t in inp.transactions
            if t.get("direction") == "debit"
            and t.get("category") in ("NEEDS", "WANTS")
            and t.get("timestamp", "")[:10] == day_str
        )
        if day_spend <= spd:
            days_within_spd += 1

    # ── Resilience Score (0–100) ──────────────────────────────────────────────
    bills_at_risk = sum(1 for bg in bill_guard if bg.at_risk)

    p1 = min(30.0, (sd / nd) * 30) if nd > 0 else 0.0   # survival coverage
    p2 = max(0.0, 25.0 - bills_at_risk * 8)               # bill protection
    p3 = (days_within_spd / 7) * 20                       # spending discipline
    p4 = max(0.0, 15.0 - income_cv * 15)                  # income stability
    p5 = min(10.0, ef_progress * 10)                       # emergency fund

    resilience_score = p1 + p2 + p3 + p4 + p5

    if resilience_score >= 75:
        resilience_label = "Strong"
    elif resilience_score >= 50:
        resilience_label = "Moderate"
    elif resilience_score >= 25:
        resilience_label = "Building"
    else:
        resilience_label = "Fragile"

    # ── Goals ─────────────────────────────────────────────────────────────────
    spend_last_7d = sum(
        float(t["amount"])
        for t in inp.transactions
        if t.get("direction") == "debit"
        and t.get("category") in ("NEEDS", "WANTS")
        and t.get("timestamp", "")[:10] in last_7_iso
    )
    avg_daily_spend_7d = spend_last_7d / 7
    daily_surplus = max(0.0, spd - avg_daily_spend_7d)

    goal_results: list[GoalResult] = []
    for g in inp.goals:
        saved = float(g.get("saved_amount") or 0)
        target = float(g["target_amount"])
        remaining = target - saved

        if remaining <= 0:
            days_to_goal, on_track, daily_needed = 0.0, True, 0.0
        elif daily_surplus <= 0:
            days_to_goal, on_track, daily_needed = 999.0, False, 0.0
        else:
            days_to_goal = remaining / daily_surplus
            deadline_str = g.get("deadline")
            if deadline_str:
                days_left = (date.fromisoformat(deadline_str) - today).days
                on_track = days_to_goal <= days_left
            else:
                on_track = True
            daily_needed = remaining / max(1.0, days_to_goal)

        goal_results.append(GoalResult(
            goal_id=g["id"],
            title=g["title"],
            target_amount=target,
            saved_amount=saved,
            days_to_goal=round(days_to_goal, 1),
            on_track=on_track,
            daily_needed=round(daily_needed, 2),
        ))

    # ── Risk Flags ────────────────────────────────────────────────────────────
    # OVERSPEND is checked at request time by the router — not here.
    risk_flags: list[str] = []
    if spd < 0:
        risk_flags.append("HIGH_RISK")
    elif 0 <= spd < ede:
        risk_flags.append("CRITICAL")
    if sd < nd:
        risk_flags.append("SHORTAGE_RISK")
    if any(bg.at_risk for bg in bill_guard):
        risk_flags.append("BILL_RISK")
    if income_trend == "dip":
        risk_flags.append("INCOME_DIP")

    return EngineOutput(
        cb=round(cb, 2),
        ub=round(ub, 2),
        ade=round(ade, 2),
        ede=round(ede, 2),
        min_reserve=round(min_reserve, 2),
        spd=round(spd, 2),
        sd=round(sd, 2),
        nd=nd,
        resilience_score=round(resilience_score, 1),
        resilience_label=resilience_label,
        pillar_scores={
            "p1": round(p1, 2),
            "p2": round(p2, 2),
            "p3": round(p3, 2),
            "p4": round(p4, 2),
            "p5": round(p5, 2),
        },
        income_trend=income_trend,
        income_cv=round(income_cv, 4),
        ef_progress=round(ef_progress, 4),
        risk_flags=risk_flags,
        bill_guard=bill_guard,
        goal_results=goal_results,
    )