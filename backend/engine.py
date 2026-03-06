from dataclasses import dataclass, field
from datetime import date, datetime
from statistics import mean, stdev
from typing import Optional
import math


# ── Input / Output dataclasses ─────────────────────────────────────────────

@dataclass
class EngineInput:
    user_id: str
    starting_balance: float
    next_income_date: Optional[date]
    expected_income: float
    transactions: list   # raw dicts from Supabase
    bills: list          # raw dicts from Supabase
    goals: list          # raw dicts from Supabase


@dataclass
class EngineOutput:
    user_id: str
    snapshot_date: str
    cb: float
    ub: float
    nd: int
    ade: float
    min_reserve: float
    spd: float
    resilience_score: int
    survival_days: float


# ── Pure math — no DB, no API calls ───────────────────────────────────────

def run_engine(inp: EngineInput) -> EngineOutput:
    today = date.today()

    # ── CB: current balance ──────────────────────────────────────
    # No wallet_balance_after in current model, use wallet math
    credits = sum(t["amount"] for t in inp.transactions if t["direction"] == "credit")
    debits  = sum(t["amount"] for t in inp.transactions if t["direction"] == "debit")
    cb = inp.starting_balance + credits - debits

    # ── ND: days to next income ──────────────────────────────────
    if inp.next_income_date:
        nd = max(1, (inp.next_income_date - today).days)
    else:
        nd = 30  # fallback if not set

    # ── UB: upcoming bills total ─────────────────────────────────
    # Sum unpaid bills due on or before next income date
    ub = 0.0
    for b in inp.bills:
        if b["is_paid"]:
            continue
        try:
            due = date.fromisoformat(b["due_date"][:10])
        except Exception:
            continue
        if inp.next_income_date is None or due <= inp.next_income_date:
            ub += float(b["amount"])

    # ── ADE: avg daily expense (needs + wants, last 30 days) ─────
    thirty_days_ago = today.replace(day=max(1, today.day - 30))
    recent_debits = [
        t for t in inp.transactions
        if t["direction"] == "debit"
        and t["category"] in ("NEEDS", "WANTS")
        and _parse_date(t["timestamp"]) >= thirty_days_ago
    ]
    ade = sum(t["amount"] for t in recent_debits) / 30 if recent_debits else 1.0

    # ── EDE: essential daily expense (needs only, last 30 days) ──
    essential_debits = [t for t in recent_debits if t["category"] == "NEEDS"]
    ede = sum(t["amount"] for t in essential_debits) / 30 if essential_debits else 0.5

    # ── MIN_RESERVE, SPD ─────────────────────────────────────────
    min_reserve = 3 * ede
    asb = cb - ub - min_reserve
    spd = asb / nd

    # ── SD: survival days ─────────────────────────────────────────
    sd = (cb - ub) / ade if ade > 0 else 0.0

    # ── Resilience score ─────────────────────────────────────────
    # P1 — survival coverage (max 30)
    p1 = min(30.0, (sd / nd) * 30) if nd > 0 else 0.0

    # P2 — bill protection (max 25)
    bills_at_risk = 0
    for b in inp.bills:
        if b["is_paid"]:
            continue
        try:
            due = date.fromisoformat(b["due_date"][:10])
        except Exception:
            continue
        days_until = max(0, (due - today).days)
        projected = cb - (ade * days_until)
        if projected < float(b["amount"]):
            bills_at_risk += 1
    p2 = max(0.0, 25 - bills_at_risk * 8)

    # P3 — spending discipline: days within SPD last 7 days (max 20)
    seven_days_ago = today.replace(day=max(1, today.day - 7))
    days_within = _days_within_spd(inp.transactions, spd, seven_days_ago, today)
    p3 = (days_within / 7) * 20

    # P4 — income stability (max 15)
    weekly_income = _weekly_income(inp.transactions)
    if len(weekly_income) >= 2 and mean(weekly_income) > 0:
        cv = stdev(weekly_income) / mean(weekly_income)
    else:
        cv = 0.0
    p4 = max(0.0, 15 - cv * 15)

    # P5 — emergency fund (max 10)
    ef_target   = 3 * ade
    ef_saved    = max(0.0, cb - ub - ade)
    ef_progress = min(1.0, ef_saved / ef_target) if ef_target > 0 else 0.0
    p5 = ef_progress * 10

    resilience_score = int(round(p1 + p2 + p3 + p4 + p5))
    resilience_score = max(0, min(100, resilience_score))

    return EngineOutput(
        user_id          = inp.user_id,
        snapshot_date    = today.isoformat(),
        cb               = round(cb, 2),
        ub               = round(ub, 2),
        nd               = nd,
        ade              = round(ade, 2),
        min_reserve      = round(min_reserve, 2),
        spd              = round(spd, 2),
        resilience_score = resilience_score,
        survival_days    = round(sd, 2),
    )


# ── Helpers ────────────────────────────────────────────────────────────────

def _parse_date(ts: str) -> date:
    try:
        return datetime.fromisoformat(ts[:10]).date()
    except Exception:
        return date.today()


def _weekly_income(transactions: list) -> list:
    """Bucket income credits into 4 weekly totals."""
    today = date.today()
    buckets = [0.0, 0.0, 0.0, 0.0]
    for t in transactions:
        if t["direction"] != "credit" or t["category"] != "INCOME":
            continue
        d = _parse_date(t["timestamp"])
        days_ago = (today - d).days
        if days_ago < 7:
            buckets[0] += float(t["amount"])
        elif days_ago < 14:
            buckets[1] += float(t["amount"])
        elif days_ago < 21:
            buckets[2] += float(t["amount"])
        elif days_ago < 28:
            buckets[3] += float(t["amount"])
    return buckets


def _days_within_spd(transactions: list, spd: float,
                      from_date: date, to_date: date) -> int:
    """Count days in range where total spend <= SPD."""
    from collections import defaultdict
    daily = defaultdict(float)
    for t in transactions:
        if t["direction"] != "debit":
            continue
        d = _parse_date(t["timestamp"])
        if from_date <= d <= to_date:
            daily[d] += float(t["amount"])
    within = sum(1 for spend in daily.values() if spend <= spd)
    # Days with no spend also count as within SPD
    days_with_data = len(daily)
    days_no_spend  = 7 - days_with_data
    return within + max(0, days_no_spend)