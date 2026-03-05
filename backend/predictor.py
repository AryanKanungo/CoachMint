"""
prediction/predictor.py
CoachMint — Time Traveler

Reads Supabase directly. Pure statistics — no ML, no Gemini.

run_prediction(user_id, db) does two core things:
  1. Distance Logic  — infer the real next income date from credit history
  2. Oxygen Logic    — recalculate survival_days from a weighted predicted burn rate

Then writes:
  • predictions table  — 14-day daily expense curve + projected income event
  • financial_snapshots — updated survival_days, income_trend, risk_flags
"""

from __future__ import annotations

import statistics
import uuid
from collections import defaultdict
from datetime import date, timedelta
from typing import Optional


# ── Main entry point ──────────────────────────────────────────────────────────

def run_prediction(user_id: str, db) -> dict:
    today = date.today()
    today_iso = today.isoformat()

    # ── Fetch data ─────────────────────────────────────────────────────────────
    ninety_days_ago = (today - timedelta(days=90)).isoformat()
    twenty_one_days_ago = (today - timedelta(days=21)).isoformat()

    txns_90d: list[dict] = (
        db.table("transactions")
        .select("*")
        .eq("user_id", user_id)
        .gte("timestamp", ninety_days_ago)
        .execute()
        .data
    ) or []

    bills: list[dict] = (
        db.table("bills")
        .select("*")
        .eq("user_id", user_id)
        .eq("is_paid", False)
        .execute()
        .data
    ) or []

    profile: dict = (
        db.table("user_profile")
        .select("*")
        .eq("user_id", user_id)
        .single()
        .execute()
        .data
    ) or {}

    # Load today's snapshot — predictor enriches it, not replace it
    snapshot_rows = (
        db.table("financial_snapshots")
        .select("*")
        .eq("user_id", user_id)
        .eq("snapshot_date", today_iso)
        .execute()
        .data
    ) or []
    snapshot: dict = snapshot_rows[0] if snapshot_rows else {}

    cb: float = float(snapshot.get("cb") or 0)
    ub: float = float(snapshot.get("ub") or 0)
    historical_ade: float = float(snapshot.get("ade") or 1)

    # ── 1. DISTANCE LOGIC — Dynamic next income date ───────────────────────────
    # Query credit transactions, sorted oldest → newest.
    # Average the gaps between consecutive inflows to predict the next one.

    credit_txns = sorted(
        [t for t in txns_90d if t.get("direction") == "credit"],
        key=lambda t: t["timestamp"],
    )

    predicted_next_income_date: date
    avg_income_interval_days: Optional[float] = None
    income_confidence: float = 0.4

    if len(credit_txns) >= 2:
        credit_dates = [date.fromisoformat(t["timestamp"][:10]) for t in credit_txns]
        intervals = [
            (credit_dates[i] - credit_dates[i - 1]).days
            for i in range(1, len(credit_txns))
            if (credit_dates[i] - credit_dates[i - 1]).days > 0  # skip same-day credits
        ]
        if intervals:
            avg_income_interval_days = statistics.mean(intervals)
            last_credit_date = credit_dates[-1]
            predicted_next_income_date = last_credit_date + timedelta(
                days=round(avg_income_interval_days)
            )
            # Confidence rises with more data points, max 0.85
            income_confidence = min(0.85, 0.5 + len(intervals) * 0.05)
        else:
            predicted_next_income_date = _fallback_income_date(profile, today)
    else:
        predicted_next_income_date = _fallback_income_date(profile, today)

    # INCOME_DELAY: today has already passed the predicted income date
    income_delay = today > predicted_next_income_date

    # ── 2. OXYGEN LOGIC — Predicted burn rate & survival days ─────────────────
    # Weighted burn: last 7 days count 2×, days 8–14 count 1×.
    # Gives recent overspend more signal than stale history.

    seven_days_ago_iso = (today - timedelta(days=7)).isoformat()
    fourteen_days_ago_iso = (today - timedelta(days=14)).isoformat()

    spend_last_7d = sum(
        float(t["amount"])
        for t in txns_90d
        if t.get("direction") == "debit"
        and t.get("category") in ("NEEDS", "WANTS")
        and t.get("timestamp", "")[:10] >= seven_days_ago_iso
    )
    spend_8_14d = sum(
        float(t["amount"])
        for t in txns_90d
        if t.get("direction") == "debit"
        and t.get("category") in ("NEEDS", "WANTS")
        and fourteen_days_ago_iso <= t.get("timestamp", "")[:10] < seven_days_ago_iso
    )

    # (2 × last_7d_daily + 1 × prior_7d_daily) / 3 — weighted average daily burn
    daily_last_7 = spend_last_7d / 7
    daily_8_14 = spend_8_14d / 7
    predicted_burn_rate = max((daily_last_7 * 2 + daily_8_14) / 3, 1.0)

    # Re-derived survival days using the predicted burn instead of ADE
    predicted_survival_days = (cb - ub) / predicted_burn_rate

    # ── 3. INSERT predictions (14-day expense curve + income event) ────────────

    # Delete today's stale predictions before inserting fresh ones
    db.table("predictions").delete().eq("user_id", user_id).eq(
        "prediction_date", today_iso
    ).execute()

    rows_to_insert: list[dict] = []

    # Daily expense projection — confidence degrades linearly with horizon
    for n in range(1, 15):
        target_date = (today + timedelta(days=n)).isoformat()
        # Sum of bills due on or before this target date
        bills_due = sum(
            float(b["amount"])
            for b in bills
            if date.fromisoformat(b["due_date"]) <= date.fromisoformat(target_date)
        )
        projected_balance = cb - (predicted_burn_rate * n) - bills_due
        confidence = round(max(0.30, 0.95 - (n - 1) * 0.05), 2)

        rows_to_insert.append({
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "prediction_date": today_iso,
            "target_date": target_date,
            "type": "expense",
            "predicted_amount": round(predicted_burn_rate * n, 2),
            "confidence_score": confidence,
        })

    # Income projection
    recent_credit_amounts = [float(t["amount"]) for t in credit_txns]
    predicted_income_amount = (
        statistics.mean(recent_credit_amounts)
        if recent_credit_amounts
        else float(profile.get("expected_income") or 0)
    )
    rows_to_insert.append({
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "prediction_date": today_iso,
        "target_date": predicted_next_income_date.isoformat(),
        "type": "income",
        "predicted_amount": round(predicted_income_amount, 2),
        "confidence_score": round(income_confidence, 2),
    })

    db.table("predictions").insert(rows_to_insert).execute()

    # ── 4. UPDATE financial_snapshots ─────────────────────────────────────────
    # Only enrich — never overwrite core engine fields (cb, ub, ade, nd, spd, etc.)

    # Recalculate income_trend from 90d window (4-week buckets)
    wi = [0.0, 0.0, 0.0, 0.0]
    for t in txns_90d:
        if t.get("direction") == "credit" and t.get("category") == "INCOME":
            txn_date = date.fromisoformat(t["timestamp"][:10])
            days_ago = (today - txn_date).days
            week_idx = days_ago // 7
            if 0 <= week_idx < 4:
                wi[3 - week_idx] += float(t["amount"])

    mean_wi = sum(wi) / 4
    if mean_wi == 0:
        income_trend = snapshot.get("income_trend") or "stable"
    else:
        if wi[3] < 0.70 * mean_wi:
            income_trend = "dip"
        elif wi[3] > 1.30 * mean_wi:
            income_trend = "surge"
        else:
            income_trend = "stable"

    # Merge INCOME_DELAY into risk_flags without clobbering engine-set flags
    current_flags: list[str] = list(snapshot.get("risk_flags") or [])
    if income_delay and "INCOME_DELAY" not in current_flags:
        current_flags.append("INCOME_DELAY")
    elif not income_delay and "INCOME_DELAY" in current_flags:
        current_flags.remove("INCOME_DELAY")

    # ✅ NEW: Safely updates ONLY the specified columns
    db.table("financial_snapshots").update(
        {
            "survival_days": round(predicted_survival_days, 2),
            "income_trend": income_trend,
            "risk_flags": current_flags,
        }
    ).eq("user_id", user_id).eq("snapshot_date", today_iso).execute()

    # ── 5. Analytics (returned to caller — used by Flutter charts) ────────────
    spend_trend = _spend_trend(txns_90d, today)
    income_range = _income_range(wi)
    recurring = _recurring_bills(txns_90d, today)
    dow_pattern = _dow_spend_pattern(txns_90d, today, twenty_one_days_ago)

    return {
        # Distance & Oxygen core outputs
        "predicted_next_income_date": predicted_next_income_date.isoformat(),
        "avg_income_interval_days": (
            round(avg_income_interval_days, 1) if avg_income_interval_days else None
        ),
        "income_delay": income_delay,
        "predicted_burn_rate": round(predicted_burn_rate, 2),
        "predicted_survival_days": round(predicted_survival_days, 2),
        "income_trend": income_trend,
        "risk_flags": current_flags,
        # Flutter chart analytics
        "spend_trend": spend_trend,
        "income_range": income_range,
        "recurring_bills": recurring,
        "dow_spend_pattern": dow_pattern,
        "predictions_inserted": len(rows_to_insert),
    }


# ── Analytics helpers — all pure functions ────────────────────────────────────

def _fallback_income_date(profile: dict, today: date) -> date:
    """Use profile's next_income_date if set, else 30 days from today."""
    raw = profile.get("next_income_date")
    if raw:
        try:
            return date.fromisoformat(raw)
        except ValueError:
            pass
    return today + timedelta(days=30)


def _spend_trend(txns: list[dict], today: date) -> dict:
    """
    Compare WANTS spend this week vs last week.
    Returns {"wants_change_pct": float, "label": "up 23%" | "down 14%" | "flat"}
    """
    seven_days_ago = (today - timedelta(days=7)).isoformat()
    fourteen_days_ago = (today - timedelta(days=14)).isoformat()

    this_week = sum(
        float(t["amount"])
        for t in txns
        if t.get("direction") == "debit"
        and t.get("category") == "WANTS"
        and t.get("timestamp", "")[:10] >= seven_days_ago
    )
    last_week = sum(
        float(t["amount"])
        for t in txns
        if t.get("direction") == "debit"
        and t.get("category") == "WANTS"
        and fourteen_days_ago <= t.get("timestamp", "")[:10] < seven_days_ago
    )

    if last_week == 0:
        pct = 0.0
        label = "flat"
    else:
        pct = round((this_week - last_week) / last_week * 100, 1)
        if abs(pct) < 2:
            label = "flat"
        elif pct > 0:
            label = f"up {abs(pct):.0f}%"
        else:
            label = f"down {abs(pct):.0f}%"

    return {"wants_change_pct": pct, "label": label}


def _income_range(wi: list[float]) -> dict:
    """
    Income forecast range from last 4 weekly buckets.
    Returns {"low": float, "mid": float, "high": float}
    """
    non_zero = [w for w in wi if w > 0] or [0.0]
    return {
        "low": round(min(non_zero), 2),
        "mid": round(statistics.mean(non_zero), 2),
        "high": round(max(non_zero), 2),
    }


def _recurring_bills(txns: list[dict], today: date) -> list[dict]:
    """
    Detect likely recurring bills: payees that appear 2+ times in 60 days
    with amounts within ±5% and transaction dates within ±3 days each month.

    Returns list of {payee, likely_amount, likely_day_of_month}
    """
    sixty_days_ago = (today - timedelta(days=60)).isoformat()
    debits_60d = [
        t for t in txns
        if t.get("direction") == "debit"
        and t.get("timestamp", "")[:10] >= sixty_days_ago
    ]

    # Group by payee
    by_payee: dict[str, list[dict]] = defaultdict(list)
    for t in debits_60d:
        payee = (t.get("payee") or "").strip().lower()
        if payee:
            by_payee[payee].append(t)

    results = []
    for payee, entries in by_payee.items():
        if len(entries) < 2:
            continue

        amounts = [float(e["amount"]) for e in entries]
        avg_amount = statistics.mean(amounts)

        # Amount consistency: all within ±5% of the average
        if not all(abs(a - avg_amount) / max(avg_amount, 1) <= 0.05 for a in amounts):
            continue

        # Date consistency: days of month within ±3 of each other
        days_of_month = [
            date.fromisoformat(e["timestamp"][:10]).day for e in entries
        ]
        avg_day = statistics.mean(days_of_month)
        if not all(abs(d - avg_day) <= 3 for d in days_of_month):
            continue

        results.append({
            "payee": payee.title(),
            "likely_amount": round(avg_amount, 2),
            "likely_day_of_month": round(avg_day),
        })

    return results


def _dow_spend_pattern(
    txns: list[dict], today: date, since_iso: str
) -> dict[str, float]:
    """
    Average debit spend per weekday over the provided window (21+ days).
    Returns {"Mon": float, "Tue": float, ..., "Sun": float}
    """
    DAY_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    totals: dict[int, float] = defaultdict(float)
    counts: dict[int, int] = defaultdict(int)

    for t in txns:
        ts = t.get("timestamp", "")[:10]
        if ts < since_iso:
            continue
        if t.get("direction") != "debit" or t.get("category") not in ("NEEDS", "WANTS"):
            continue
        wd = date.fromisoformat(ts).weekday()  # 0=Mon, 6=Sun
        totals[wd] += float(t["amount"])
        counts[wd] += 1

    # Count unique calendar days per weekday in the window
    start = date.fromisoformat(since_iso)
    day_occurrences: dict[int, int] = defaultdict(int)
    cursor = start
    while cursor <= today:
        day_occurrences[cursor.weekday()] += 1
        cursor += timedelta(days=1)

    return {
        DAY_NAMES[wd]: round(totals[wd] / max(day_occurrences[wd], 1), 2)
        for wd in range(7)
    }