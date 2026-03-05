"""
Resilience Score — 5 pillars, 0–100.

Updated from original 4-pillar version. Changes explained inline.

────────────────────────────────────────────────────────────────────────────────
  P1  Survival Coverage    (max 30 pts)
      min(30, (SD / ND) × 30)
      Original was 40pts. Reduced to 30 to make room for P5.
      Measures: can you make it to next income without running out?

  P2  Bill Protection      (max 25 pts)
      max(0, 25 − bills_at_risk × 8)
      Unchanged from original. Each at-risk bill deducts 8 pts.
      Measures: are your upcoming bills going to be covered?

  P3  Spending Discipline  (max 20 pts)
      (days_within_spd_last_7 / 7) × 20
      Unchanged. Checks last 7 days against SPD.
      Measures: is the user actually staying within their daily limit?

  P4  Income Stability     (max 15 pts)
      max(0, 15 − CV × 15)
      NEW pillar. Replaces a simpler income_dip binary check.
      Uses CV (coefficient of variation) from income_trend.py.
      Why: two users with the same average income get different scores
      if one earns consistently and the other swings wildly. The volatile
      earner is genuinely more fragile — this captures that correctly.
      Gig workers with irregular income naturally score lower here,
      which is accurate and actionable.

  P5  Emergency Fund       (max 10 pts)
      ef_progress × 10
      NEW pillar. Makes emergency fund progress visible in the score.
      Rewards building a buffer. Motivates saving beyond just surviving.

  TOTAL = P1 + P2 + P3 + P4 + P5  (max 100)

Labels:
  ≥ 75  Strong    (was "Strong" in original — unchanged)
  ≥ 50  Moderate  (was "Moderate" — unchanged)
  ≥ 25  Building  (replaces "Low" — same math, less punitive label)
  < 25  Fragile   (replaces nothing — new bottom tier for severe cases)
────────────────────────────────────────────────────────────────────────────────
"""

from datetime import date, timedelta
from financial_engine.variables import Transaction, BillGuardResult


def _days_within_spd(transactions: list[Transaction], spd: float) -> int:
    """
    Count days in the last 7 (including today) where total spending ≤ SPD.
    Days with zero transactions are counted as within limit.
    """
    today       = date.today()
    daily: dict[str, float] = {}

    for txn in transactions:
        if txn.type != "debit" or txn.category_top in ("savings", "transfer"):
            continue
        day = txn.transaction_date[:10]
        daily[day] = daily.get(day, 0.0) + txn.amount

    count = 0
    for i in range(7):
        day = str(today - timedelta(days=i))
        if daily.get(day, 0.0) <= spd:
            count += 1

    return count


def calc_resilience(
    survival_days:  float,
    days_to_income: int,
    bill_guard:     list[BillGuardResult],
    transactions:   list[Transaction],
    income_cv:      float,
    ef_progress:    float,             # 0.0 → 1.0 from calc_emergency_fund
    spd:            float,
) -> tuple[float, str, dict]:
    """
    Returns (score: float, label: str, pillar_breakdown: dict).
    """
    nd = max(1, days_to_income)

    p1 = round(min(30.0, max(0.0, (survival_days / nd) * 30)), 1)

    bills_at_risk = len([b for b in bill_guard if b.at_risk])
    p2 = round(max(0.0, 25.0 - (bills_at_risk * 8)), 1)

    days_ok = _days_within_spd(transactions, spd)
    p3 = round((days_ok / 7) * 20, 1)

    p4 = round(max(0.0, 15.0 - (income_cv * 15)), 1)

    p5 = round(min(10.0, ef_progress * 10), 1)

    score = round(p1 + p2 + p3 + p4 + p5, 1)

    if score >= 75:
        label = "Strong"
    elif score >= 50:
        label = "Moderate"
    elif score >= 25:
        label = "Building"
    else:
        label = "Fragile"

    pillars = {
        "p1_survival":   p1,
        "p2_bills":      p2,
        "p3_discipline": p3,
        "p4_stability":  p4,
        "p5_emergency":  p5,
    }

    return score, label, pillars
