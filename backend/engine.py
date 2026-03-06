from __future__ import annotations
import statistics
from dataclasses import dataclass, field, asdict
from datetime import date, timedelta
from typing import Optional

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
    days_to_goal: float
    on_track: bool
    daily_needed: float

@dataclass
class EngineInput:
    user_id: str
    starting_balance: float
    next_income_date: date
    expected_income: float
    transactions: list
    all_transactions: list
    bills: list
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
    sd: float
    nd: int
    resilience_score: float
    resilience_label: str
    pillar_scores: dict
    income_trend: str
    income_cv: float
    ef_progress: float
    risk_flags: list[str]
    bill_guard: list[BillGuardResult]
    goal_results: list[GoalResult]

def build_input(user_id: str, db) -> EngineInput:
    today = date.today()
    thirty_days_ago = (today - timedelta(days=30)).isoformat()
    profile = db.table("user_profile").select("*").eq("user_id", user_id).single().execute().data
    transactions_30d = db.table("transactions").select("*").eq("user_id", user_id).gte("timestamp", thirty_days_ago).execute().data or []
    all_transactions = db.table("transactions").select("txn_id, amount, direction").eq("user_id", user_id).execute().data or []
    bills = db.table("bills").select("*").eq("user_id", user_id).eq("is_paid", False).execute().data or []
    goals = db.table("goals").select("*").eq("user_id", user_id).execute().data or []
    raw_nid = profile.get("next_income_date") if profile else None
    next_income_date = date.fromisoformat(raw_nid) if raw_nid else today + timedelta(days=30)
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
    db.table("financial_snapshots").upsert({
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
    }, on_conflict="user_id,snapshot_date").execute()

def run_engine(inp: EngineInput) -> EngineOutput:
    today = inp.today
    total_credits = sum(float(t["amount"]) for t in inp.all_transactions if t.get("direction") == "credit")
    total_debits = sum(float(t["amount"]) for t in inp.all_transactions if t.get("direction") == "debit")
    cb = inp.starting_balance + total_credits - total_debits
    ub = sum(float(b["amount"]) for b in inp.bills if date.fromisoformat(b["due_date"]) <= inp.next_income_date)
    nd = max(1, (inp.next_income_date - today).days)
    expense_30d = sum(float(t["amount"]) for t in inp.transactions if t.get("direction") == "debit" and t.get("category") in ("NEEDS", "WANTS"))
    ade = max(expense_30d / 30, 1.0)
    essential_30d = sum(float(t["amount"]) for t in inp.transactions if t.get("direction") == "debit" and t.get("category") == "NEEDS")
    ede = max(essential_30d / 30, 1.0)
    min_reserve = 3 * ede
    spd = (cb - ub - min_reserve) / nd
    sd = (cb - ub) / ade
    bill_guard = []
    for bill in inp.bills:
        due = date.fromisoformat(bill["due_date"])
        days_until_due = max(0, (due - today).days)
        other_bills_sum = sum(float(b["amount"]) for b in inp.bills if b["id"] != bill["id"] and date.fromisoformat(b["due_date"]) <= due)
        projected = cb - (ade * days_until_due) - other_bills_sum
        bill_amount = float(bill["amount"])
        bill_guard.append(BillGuardResult(bill_id=bill["id"], name=bill["name"], amount=bill_amount, due_date=bill["due_date"], projected_balance_at_due=round(projected, 2), at_risk=projected < bill_amount, shortfall=round(max(0.0, bill_amount - projected), 2)))
    wi = [0.0, 0.0, 0.0, 0.0]
    for t in inp.transactions:
        if t.get("direction") == "credit" and t.get("category") == "INCOME":
            txn_date = date.fromisoformat(t["timestamp"][:10])
            week_idx = (today - txn_date).days // 7
            if 0 <= week_idx < 4: wi[3 - week_idx] += float(t["amount"])
    mean_wi = sum(wi) / 4
    income_trend = "stable"
    income_cv = 0.0
    if mean_wi > 0:
        if wi[3] < 0.70 * mean_wi: income_trend = "dip"
        elif wi[3] > 1.30 * mean_wi: income_trend = "surge"
        try: income_cv = statistics.stdev(wi) / mean_wi
        except: income_cv = 0.0
    ef_target = 3 * ade
    ef_saved = max(0.0, cb - ub - ade)
    ef_progress = min(1.0, ef_saved / ef_target) if ef_target > 0 else 0.0
    last_7_iso = {(today - timedelta(days=i)).isoformat() for i in range(7)}
    days_within_spd = 0
    for day_str in last_7_iso:
        day_spend = sum(float(t["amount"]) for t in inp.transactions if t.get("direction") == "debit" and t.get("category") in ("NEEDS", "WANTS") and t.get("timestamp", "")[:10] == day_str)
        if day_spend <= spd: days_within_spd += 1
    bills_at_risk = sum(1 for bg in bill_guard if bg.at_risk)
    p1 = min(30.0, (sd / nd) * 30) if nd > 0 else 0.0
    p2 = max(0.0, 25.0 - bills_at_risk * 8)
    p3 = (days_within_spd / 7) * 20
    p4 = max(0.0, 15.0 - income_cv * 15)
    p5 = min(10.0, ef_progress * 10)
    resilience_score = p1 + p2 + p3 + p4 + p5
    resilience_label = "Strong" if resilience_score >= 75 else "Moderate" if resilience_score >= 50 else "Building" if resilience_score >= 25 else "Fragile"
    risk_flags = []
    if spd < 0: risk_flags.append("HIGH_RISK")
    elif 0 <= spd < ede: risk_flags.append("CRITICAL")
    if sd < nd: risk_flags.append("SHORTAGE_RISK")
    if bills_at_risk > 0: risk_flags.append("BILL_RISK")
    if income_trend == "dip": risk_flags.append("INCOME_DIP")
    return EngineOutput(cb=round(cb, 2), ub=round(ub, 2), ade=round(ade, 2), ede=round(ede, 2), min_reserve=round(min_reserve, 2), spd=round(spd, 2), sd=round(sd, 2), nd=nd, resilience_score=round(resilience_score, 1), resilience_label=resilience_label, pillar_scores={"p1": round(p1, 2), "p2": round(p2, 2), "p3": round(p3, 2), "p4": round(p4, 2), "p5": round(p5, 2)}, income_trend=income_trend, income_cv=round(income_cv, 4), ef_progress=round(ef_progress, 4), risk_flags=risk_flags, bill_guard=bill_guard, goal_results=[])

def execute_full_pipeline(user_id: str, db):
    """The entry point for real-time recalculation."""
    inp = build_input(user_id, db)
    out = run_engine(inp)
    upsert_snapshot(user_id, out, db)
    return out