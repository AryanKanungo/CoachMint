"""
Income Trend Detection + Volatility (CV).

Groups income credits (category_top == "income") into 4 weekly buckets.
Week index 0 = oldest, week index 3 = this week (most recent).

Trend thresholds (agreed):
    dip    → this_week < 70%  of mean(WI[0..3])
    surge  → this_week > 130% of mean(WI[0..3])
    stable → everything else

CV (coefficient of variation) = std_dev(WI) / mean(WI)
    Measures income volatility independent of income level.
    A gig worker earning ₹4000/week consistently has low CV.
    The same worker with wildly swinging weeks has high CV.
    Used in resilience score Pillar P4.

Requires at least 2 non-zero weeks to be meaningful.
Returns ("stable", 0.0) when insufficient data.
"""

import math
from datetime import date
from financial_engine.variables import Transaction


def _bucket_weekly_income(transactions: list[Transaction], weeks: int = 4) -> list[float]:
    """
    Returns list of weekly income totals, length = weeks, oldest first.
    Week 3 (last element) = current week (most recent 7 days).
    """
    today   = date.today()
    buckets = [0.0] * weeks

    for txn in transactions:
        if txn.type != "credit" or txn.category_top != "income":
            continue

        txn_date = date.fromisoformat(txn.transaction_date[:10])
        days_ago = (today - txn_date).days
        week_idx = days_ago // 7   # 0 = this week, 1 = last week, etc.

        if week_idx < weeks:
            # fill from the right: week_idx 0 → buckets[-1] (most recent)
            buckets[weeks - 1 - week_idx] += txn.amount

    return buckets


def calc_income_trend(transactions: list[Transaction]) -> tuple[str, float]:
    """
    Returns (trend: str, cv: float).
    """
    weekly   = _bucket_weekly_income(transactions)
    non_zero = [w for w in weekly if w > 0]

    if len(non_zero) < 2:
        return "stable", 0.0

    mean = sum(weekly) / len(weekly)
    if mean == 0:
        return "stable", 0.0

    variance = sum((w - mean) ** 2 for w in weekly) / len(weekly)
    std_dev  = math.sqrt(variance)
    cv       = round(std_dev / mean, 3)

    this_week = weekly[-1]

    if this_week < 0.70 * mean:
        trend = "dip"
    elif this_week > 1.30 * mean:
        trend = "surge"
    else:
        trend = "stable"

    return trend, cv
