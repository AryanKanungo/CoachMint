# ==============================================================================
# CoachMint Prediction Engine — main.py  (Final)
# Single-file monolith: schemas, DB pool, statistical engine, MC, routes.
#
# PATCHES APPLIED:
#   [P1]  Timezone-aware → naive date cast via .astimezone(timezone.utc).date()
#   [P2]  CPU-bound compute lifted off event loop via run_in_threadpool
#   [P3]  /predict/{user_id} protected by X-API-KEY header dependency
#   [P4]  Bill deduplication — recurring-only, correct modular month-end wrap
#   [P5]  fetch_bills_in_window fetches recurring bills regardless of paid status
#   [P6]  Gig Compound Poisson rewritten with flattened np.add.at (no OOM 3D tensor)
#   [P7]  Salaried trend uses ±3-day window credit landing check, not 45d ratio
#   [P8]  Holt-Winters trims leading zeros before length guard (no GIGO)
#   [P9]  ADE and EDE floored at max(0.01, ...) before ratio / division
#   [P10] MC RNG seed derived deterministically from user_id.int % 2**32
#   [P11] One-time bills skipped in deduplicator (no organic data destruction)
#   [P12] Month-end wrap uses modular day_diff >= (last_day - window) check
#   [P13] _income_trend accepts income_freq; lookback derived from _FREQ_DAYS
# ==============================================================================

from __future__ import annotations

import calendar
import json
import logging
import secrets
from contextlib import asynccontextmanager
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from functools import lru_cache
from typing import Optional
from uuid import UUID

import asyncpg
import numpy as np
from dateutil.relativedelta import relativedelta
from fastapi import Depends, FastAPI, HTTPException, Security
from fastapi.concurrency import run_in_threadpool
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import APIKeyHeader
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings

try:
    from statsmodels.tsa.holtwinters import ExponentialSmoothing
    _HAS_STATSMODELS = True
except ImportError:
    _HAS_STATSMODELS = False

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# ==============================================================================
# SECTION 1 — Configuration
# ==============================================================================

class Settings(BaseSettings):
    DATABASE_URL:         str
    API_KEY:              str
    MC_ITERATIONS:        int = 5_000
    FORECAST_HORIZON:     int = 14
    COLD_START_MIN_DAYS:  int = 14
    RESILIENCE_STRONG:    int = 75
    RESILIENCE_MODERATE:  int = 50
    RESILIENCE_BUILDING:  int = 25

    class Config:
        env_file = ".env"


@lru_cache()
def get_settings() -> Settings:
    return Settings()


# ==============================================================================
# SECTION 2 — API Key Auth  [P3]
# ==============================================================================

_api_key_header = APIKeyHeader(name="X-API-KEY", auto_error=True)


async def verify_api_key(key: str = Security(_api_key_header)) -> str:
    if not secrets.compare_digest(key, get_settings().API_KEY):
        raise HTTPException(status_code=403, detail="Invalid or missing API key.")
    return key


# ==============================================================================
# SECTION 3 — Database pool
# ==============================================================================

_pool: asyncpg.Pool | None = None


async def init_pool() -> None:
    global _pool
    _pool = await asyncpg.create_pool(
        dsn=get_settings().DATABASE_URL,
        min_size=2,
        max_size=10,
        command_timeout=30,
        statement_cache_size=50,
    )


async def close_pool() -> None:
    global _pool
    if _pool:
        await _pool.close()
        _pool = None


def get_pool() -> asyncpg.Pool:
    if _pool is None:
        raise RuntimeError("DB pool not initialised.")
    return _pool


# ==============================================================================
# SECTION 4 — Pydantic schemas
# ==============================================================================

class BalanceCurve(BaseModel):
    dates: list[str]
    p10:   list[float]
    p50:   list[float]
    p90:   list[float]


class PillarScores(BaseModel):
    income_stability: float = Field(..., ge=0, le=100)
    expense_control:  float = Field(..., ge=0, le=100)
    bill_coverage:    float = Field(..., ge=0, le=100)
    goal_progress:    float = Field(..., ge=0, le=100)


class PredictionResponse(BaseModel):
    user_id:                  UUID
    snapshot_date:            date
    wallet_balance:           float
    upcoming_bills_total:     float
    avg_daily_expense:        float
    essential_daily_expense:  float
    safe_to_spend_per_day:    float
    survival_days:            float
    resilience_score:         int
    resilience_label:         str
    income_trend:             str
    risk_flags:               list[str]
    balance_curve_14d:        BalanceCurve
    pillar_scores:            PillarScores
    is_cold_start:            bool
    computed_at:              datetime


class HealthResponse(BaseModel):
    status:    str
    version:   str
    timestamp: datetime


# ==============================================================================
# SECTION 5 — CRUD / DB queries
# ==============================================================================

def _to_date(val) -> Optional[date]:
    """[P1] Safely convert any asyncpg date/datetime return to a naive date."""
    if val is None:
        return None
    if isinstance(val, datetime):
        return val.astimezone(timezone.utc).date()
    if isinstance(val, date):
        return val
    raise TypeError(f"Cannot convert {type(val)} to date")


async def db_fetch_user(pool: asyncpg.Pool, user_id: UUID) -> Optional[dict]:
    row = await pool.fetchrow(
        "SELECT id, income_type FROM public.users WHERE id = $1", user_id
    )
    return dict(row) if row else None


async def db_fetch_profile(pool: asyncpg.Pool, user_id: UUID) -> Optional[dict]:
    row = await pool.fetchrow(
        """SELECT user_id, current_wallet, next_income_date,
                  expected_income, income_frequency, onboarding_complete
           FROM public.user_profile WHERE user_id = $1""",
        user_id,
    )
    if not row:
        return None
    d = dict(row)
    d["next_income_date"] = _to_date(d.get("next_income_date"))   # [P1]
    return d


async def db_fetch_transactions(
    pool: asyncpg.Pool, user_id: UUID, lookback_days: int = 90
) -> list[dict]:
    since = date.today() - timedelta(days=lookback_days)
    rows = await pool.fetch(
        """SELECT id, type, amount, category_top,
                  transaction_date, needs_review, merchant
           FROM public.transactions
           WHERE user_id          = $1
             AND transaction_date >= $2
             AND category_top     != 'transfer'
           ORDER BY transaction_date ASC""",
        user_id,
        since,
    )
    result = []
    for r in rows:
        d = dict(r)
        d["transaction_date"] = _to_date(d["transaction_date"])   # [P1]
        result.append(d)
    return result


async def db_fetch_bills(
    pool: asyncpg.Pool,
    user_id: UUID,
    window_start: date,
    window_end: date,
) -> list[dict]:
    """
    [P5] Fetch unpaid bills in window PLUS all recurring bills regardless of
    paid status so the overlay can project their next cycle.
    """
    rows = await pool.fetch(
        """SELECT id, name, amount, due_date,
                  is_recurring, recurrence_period, is_paid
           FROM public.bills
           WHERE user_id = $1
             AND (
                   (is_paid = false AND due_date BETWEEN $2 AND $3)
                   OR is_recurring = true
             )""",
        user_id,
        window_start,
        window_end,
    )
    result = []
    for r in rows:
        d = dict(r)
        d["due_date"] = _to_date(d["due_date"])                   # [P1]
        result.append(d)
    return result


async def db_fetch_goals(pool: asyncpg.Pool, user_id: UUID) -> list[dict]:
    rows = await pool.fetch(
        """SELECT id, name, target_amount, saved_amount,
                  deadline, daily_needed, status
           FROM public.goals
           WHERE user_id      = $1
             AND status       IN ('in_progress', 'on_track', 'behind')
             AND daily_needed IS NOT NULL
             AND daily_needed  > 0""",
        user_id,
    )
    return [dict(r) for r in rows]


async def db_upsert_snapshot(pool: asyncpg.Pool, snap: dict) -> None:
    await pool.execute(
        """INSERT INTO public.financial_snapshots (
               user_id, snapshot_date, wallet_balance, upcoming_bills_total,
               avg_daily_expense, essential_daily_expense, safe_to_spend_per_day,
               survival_days, resilience_score, resilience_label, income_trend,
               risk_flags, balance_curve_14d, pillar_scores
           ) VALUES (
               $1::uuid, $2::date, $3, $4, $5, $6, $7, $8,
               $9::smallint, $10, $11,
               $12::jsonb, $13::jsonb, $14::jsonb
           )
           ON CONFLICT (user_id, snapshot_date) DO UPDATE SET
               wallet_balance            = EXCLUDED.wallet_balance,
               upcoming_bills_total      = EXCLUDED.upcoming_bills_total,
               avg_daily_expense         = EXCLUDED.avg_daily_expense,
               essential_daily_expense   = EXCLUDED.essential_daily_expense,
               safe_to_spend_per_day     = EXCLUDED.safe_to_spend_per_day,
               survival_days             = EXCLUDED.survival_days,
               resilience_score          = EXCLUDED.resilience_score,
               resilience_label          = EXCLUDED.resilience_label,
               income_trend              = EXCLUDED.income_trend,
               risk_flags                = EXCLUDED.risk_flags,
               balance_curve_14d         = EXCLUDED.balance_curve_14d,
               pillar_scores             = EXCLUDED.pillar_scores,
               created_at                = NOW()""",
        snap["user_id"],
        snap["snapshot_date"],
        snap["wallet_balance"],
        snap["upcoming_bills_total"],
        snap["avg_daily_expense"],
        snap["essential_daily_expense"],
        snap["safe_to_spend_per_day"],
        snap["survival_days"],
        snap["resilience_score"],
        snap["resilience_label"],
        snap["income_trend"],
        json.dumps(snap["risk_flags"]),
        json.dumps(snap["balance_curve_14d"]),
        json.dumps(snap["pillar_scores"]),
    )


# ==============================================================================
# SECTION 6 — Feature Extraction
# ==============================================================================

@dataclass
class FeatureSet:
    CB:               float
    ND:               Optional[date]
    WI:               float
    ADE:              float
    EDE:              float
    B:                float
    G:                float
    income_type:      str
    income_trend:     str
    is_cold_start:    bool
    has_review_flags: bool
    n_transactions:   int
    days_to_income:   int


def _daily_series(
    transactions: list[dict],
    categories:   list[str],
    tx_type:      str,
    lookback:     int,
    ref_date:     date,
) -> np.ndarray:
    daily: dict[date, float] = {}
    for tx in transactions:
        if tx["type"] != tx_type:
            continue
        if categories and tx.get("category_top") not in categories:
            continue
        d = tx["transaction_date"]
        daily[d] = daily.get(d, 0.0) + float(tx["amount"])
    return np.array(
        [daily.get(ref_date - timedelta(days=i), 0.0)
         for i in range(lookback - 1, -1, -1)],
        dtype=float,
    )


# [P13] Frequency → correct pay-cycle lookback in days
_FREQ_DAYS: dict[str, int] = {
    "daily":     1,
    "weekly":    7,
    "biweekly":  14,
    "monthly":   30,
    "irregular": 30,
}


def _income_trend(
    transactions:     list[dict],
    income_type:      str,
    expected_income:  float,
    next_income_date: Optional[date],
    ref_date:         date,
    income_freq:      str = "monthly",   # [P13]
) -> str:
    """
    [P7]  Salaried/Student: checks for a credit >= 90% of expected_income
          within ±3 days of the most-recent expected pay date.
    [P13] Pay-cycle lookback derived from income_freq, not hardcoded to 30 days.
    """
    credits = [tx for tx in transactions if tx["type"] == "credit"]

    if income_type in ("salaried", "student"):
        if not expected_income or not next_income_date:
            return "stable"

        freq_days = _FREQ_DAYS.get(income_freq, 30)          # [P13]
        prev_pay  = next_income_date - timedelta(days=freq_days)

        window_start = prev_pay - timedelta(days=3)
        window_end   = prev_pay + timedelta(days=3)

        landed = any(
            float(tx["amount"]) >= 0.90 * expected_income
            and window_start <= tx["transaction_date"] <= window_end
            for tx in credits
        )
        if not landed:
            return "dip"

        total_in_window = sum(
            float(tx["amount"]) for tx in credits
            if window_start <= tx["transaction_date"] <= window_end
        )
        return "surge" if total_in_window >= 1.5 * expected_income else "stable"

    # Gig / freelancer — rate-based
    since_30 = ref_date - timedelta(days=30)
    since_7  = ref_date - timedelta(days=7)
    rate_30d = sum(float(t["amount"]) for t in credits if t["transaction_date"] >= since_30) / 30
    rate_7d  = sum(float(t["amount"]) for t in credits if t["transaction_date"] >= since_7)  / 7
    if rate_30d == 0:
        return "stable"
    ratio = rate_7d / rate_30d
    if ratio > 1.20:
        return "surge"
    if ratio < 0.80:
        return "dip"
    return "stable"


def extract_features(
    transactions:        list[dict],
    bills_in_window:     list[dict],
    goals:               list[dict],
    user_profile:        dict,
    income_type:         str,
    ref_date:            date,
    cold_start_min_days: int = 14,
    forecast_horizon:    int = 14,
) -> FeatureSet:
    CB               = float(user_profile.get("current_wallet") or 0)
    ND               = user_profile.get("next_income_date")
    expected_income  = float(user_profile.get("expected_income") or 0)
    income_freq      = user_profile.get("income_frequency", "monthly")

    tx_dates      = {tx["transaction_date"] for tx in transactions}
    oldest        = min(tx_dates) if tx_dates else ref_date
    is_cold_start = (ref_date - oldest).days < cold_start_min_days

    has_review_flags = any(tx.get("needs_review") for tx in transactions)

    # [P9] Floor at 0.01 — prevents negative ratio from refunds
    debits_30d = _daily_series(transactions, ["needs", "wants", "uncategorised"], "debit", 30, ref_date)
    ADE        = max(0.01, float(debits_30d.mean()))

    needs_30d  = _daily_series(transactions, ["needs"], "debit", 30, ref_date)
    EDE        = max(0.01, float(needs_30d.mean()))

    if income_type in ("salaried", "student"):
        freq_to_weekly = {
            "weekly": 1.0, "biweekly": 0.5,
            "monthly": 1 / 4.33, "daily": 7.0, "irregular": 1 / 4.33,
        }
        WI = expected_income * freq_to_weekly.get(income_freq, 1 / 4.33)
    else:
        since_7    = ref_date - timedelta(days=7)
        credits_7d = [float(tx["amount"]) for tx in transactions
                      if tx["type"] == "credit" and tx["transaction_date"] >= since_7]
        WI = sum(credits_7d)

    B = sum(float(b["amount"]) for b in bills_in_window if not b.get("is_paid"))
    G = sum(float(g["daily_needed"]) for g in goals)

    income_trend = _income_trend(
        transactions      = transactions,
        income_type       = income_type,
        expected_income   = expected_income,
        next_income_date  = ND,
        ref_date          = ref_date,
        income_freq       = income_freq,    # [P13]
    )

    if income_type in ("salaried", "student") and ND:
        days_to_income = max(1, (ND - ref_date).days)
    else:
        days_to_income = forecast_horizon

    return FeatureSet(
        CB=CB, ND=ND, WI=WI, ADE=ADE, EDE=EDE, B=B, G=G,
        income_type=income_type,
        income_trend=income_trend,
        is_cold_start=is_cold_start,
        has_review_flags=has_review_flags,
        n_transactions=len(transactions),
        days_to_income=days_to_income,
    )


# ==============================================================================
# SECTION 7 — Bill Deduplication  [P4, P11, P12]
# ==============================================================================

def deduplicate_bill_transactions(
    transactions:     list[dict],
    bills_in_window:  list[dict],
    amount_tolerance: float = 0.01,
    date_window_days: int   = 2,
) -> list[dict]:
    """
    [P4]  Strips historical debit transactions matching known recurring bills
          so SES doesn't learn them as organic spending — preventing double-
          charging in the Monte Carlo overlay.
    [P11] Non-recurring (one-time) bills are skipped entirely. They have no
          historical pattern; matching against them destroys organic data.
    [P12] Monthly wrap uses modular day_diff to handle end-of-month payments
          (e.g., paid on 31st against a 1st-of-month bill).
    """
    def _is_bill_proxy(tx: dict) -> bool:
        if tx["type"] != "debit":
            return False

        tx_amount: float = float(tx["amount"])
        tx_date:   date  = tx["transaction_date"]

        for bill in bills_in_window:
            # [P11] One-time bills have no past occurrence — skip
            if not bill.get("is_recurring"):
                continue

            b_amount: float = float(bill["amount"])
            b_date:   date  = bill["due_date"]
            period          = bill.get("recurrence_period")

            if abs(tx_amount - b_amount) > amount_tolerance:
                continue

            if period == "monthly":
                last_day   = calendar.monthrange(tx_date.year, tx_date.month)[1]
                target_day = min(b_date.day, last_day)
                day_diff   = abs(tx_date.day - target_day)
                # [P12] Modular wrap: 31st vs 1st → day_diff=30 ≈ 1 day before wrap
                if day_diff <= date_window_days or day_diff >= (last_day - date_window_days):
                    return True

            elif period in ("quarterly", "annual"):
                delta = (
                    relativedelta(months=3) if period == "quarterly"
                    else relativedelta(years=1)
                )
                cursor = b_date
                for _ in range(4):
                    cursor = cursor - delta
                    if cursor < tx_date - timedelta(days=date_window_days):
                        break
                    if abs((tx_date - cursor).days) <= date_window_days:
                        return True

        return False

    return [tx for tx in transactions if not _is_bill_proxy(tx)]


# ==============================================================================
# SECTION 8 — Income Model
# ==============================================================================

def _income_deterministic(
    expected_income:  float,
    next_income_date: Optional[date],
    ref_date:         date,
    horizon:          int,
    n_iter:           int,
) -> np.ndarray:
    paths = np.zeros((n_iter, horizon), dtype=float)
    if not next_income_date or not expected_income:
        return paths
    idx = (next_income_date - ref_date).days
    if 0 <= idx < horizon:
        paths[:, idx] = expected_income
    return paths


def _income_stochastic(
    transactions:  list[dict],
    ref_date:      date,
    horizon:       int,
    n_iter:        int,
    seed:          int,
    lookback_days: int = 30,
) -> np.ndarray:
    """
    [P6] Compound Poisson × LogNormal — memory-safe via flat pool + np.add.at.
    Avoids the (n_iter, horizon, max_arr) 3D tensor that caused OOM under load.
    """
    rng = np.random.default_rng(seed)

    credit_amounts = [
        float(tx["amount"]) for tx in transactions
        if tx["type"] == "credit" and float(tx["amount"]) > 0
    ]
    if not credit_amounts:
        return np.zeros((n_iter, horizon), dtype=float)

    lam    = len(credit_amounts) / lookback_days
    log_a  = np.log(credit_amounts)
    ln_mu  = float(np.mean(log_a))
    ln_sig = max(float(np.std(log_a, ddof=1)) if len(log_a) > 1 else 0.5, 0.01)

    paths    = np.zeros((n_iter, horizon), dtype=float)
    arrivals = rng.poisson(lam, size=(n_iter, horizon))
    total    = int(arrivals.sum())

    if total == 0:
        return paths

    flat_payments = rng.lognormal(ln_mu, ln_sig, size=total)

    row_idx = np.repeat(np.arange(n_iter), arrivals.sum(axis=1))
    col_idx = np.repeat(
        np.tile(np.arange(horizon), n_iter).reshape(n_iter, horizon),
        arrivals,
    ).ravel()

    np.add.at(paths, (row_idx, col_idx), flat_payments)
    return paths


def build_income_paths(
    income_type:   str,
    transactions:  list[dict],
    user_profile:  dict,
    ref_date:      date,
    horizon:       int,
    n_iter:        int,
    seed:          int,
) -> np.ndarray:
    if income_type in ("salaried", "student"):
        return _income_deterministic(
            expected_income  = float(user_profile.get("expected_income") or 0),
            next_income_date = user_profile.get("next_income_date"),
            ref_date         = ref_date,
            horizon          = horizon,
            n_iter           = n_iter,
        )
    return _income_stochastic(
        transactions  = transactions,
        ref_date      = ref_date,
        horizon       = horizon,
        n_iter        = n_iter,
        seed          = seed,
    )


# ==============================================================================
# SECTION 9 — Expense Model
# ==============================================================================

@dataclass
class ExpenseForecast:
    forecast_mean: np.ndarray
    forecast_std:  float
    is_fallback:   bool


def _wma(series: np.ndarray, horizon: int) -> ExpenseForecast:
    n = len(series)
    if n == 0 or series.sum() == 0:
        return ExpenseForecast(np.zeros(horizon), 0.01, is_fallback=True)
    w   = np.arange(1, n + 1, dtype=float)
    wma = float(np.dot(w / w.sum(), series))
    std = max(float(series.std()), 0.01)
    return ExpenseForecast(np.full(horizon, wma), std, is_fallback=True)


def _ses(series: np.ndarray, horizon: int) -> ExpenseForecast:
    """Simple Exponential Smoothing for `needs` (no weekly seasonality)."""
    if not _HAS_STATSMODELS or len(series) < 3:
        return _wma(series, horizon)
    first_nz = int(np.argmax(series > 0))
    trimmed  = series[first_nz:]
    if len(trimmed) < 3:
        return _wma(series, horizon)
    try:
        model  = ExponentialSmoothing(
            trimmed.astype(float),
            trend=None, seasonal=None,
            initialization_method="estimated",
        )
        result   = model.fit(optimized=True, use_brute=False)
        forecast = np.clip(result.forecast(steps=horizon), 0, None)
        std      = max(float(np.std(trimmed - result.fittedvalues, ddof=1)), 0.01)
        return ExpenseForecast(forecast, std, is_fallback=False)
    except Exception:
        return _wma(series, horizon)


def _holt_winters(series: np.ndarray, horizon: int) -> ExpenseForecast:
    """
    [P8] Holt-Winters additive seasonality (period=7) for `wants`.
    Trims leading zeros BEFORE the length guard — raw series is always
    shape (30,) from _build_daily, so checking len(series) was checking
    the padded length, causing GIGO fits on zero-dominated arrays.
    """
    if not _HAS_STATSMODELS:
        return _ses(series, horizon)

    # Trim leading zeros first
    if np.any(series > 0):
        first_nz = int(np.argmax(series > 0))
        trimmed  = series[first_nz:]
    else:
        trimmed = series

    # Guard against insufficient real observations for a period-7 model
    if len(trimmed) < 14:
        return _ses(series, horizon)

    try:
        model  = ExponentialSmoothing(
            trimmed.astype(float),
            trend="add",
            seasonal="add",
            seasonal_periods=7,
            initialization_method="estimated",
        )
        result   = model.fit(optimized=True, use_brute=False)
        forecast = np.clip(result.forecast(steps=horizon), 0, None)
        std      = max(float(np.std(trimmed - result.fittedvalues, ddof=1)), 0.01)
        return ExpenseForecast(forecast, std, is_fallback=False)
    except Exception:
        return _ses(series, horizon)


def _build_daily(
    transactions: list[dict],
    categories:   list[str],
    lookback:     int,
    ref_date:     date,
) -> np.ndarray:
    daily: dict[date, float] = {}
    for tx in transactions:
        if tx["type"] != "debit":
            continue
        if tx.get("category_top") not in categories:
            continue
        d = tx["transaction_date"]
        daily[d] = daily.get(d, 0.0) + float(tx["amount"])
    return np.array(
        [daily.get(ref_date - timedelta(days=i), 0.0)
         for i in range(lookback - 1, -1, -1)],
        dtype=float,
    )


def model_expenses(
    transactions:  list[dict],
    ref_date:      date,
    horizon:       int,
    is_cold_start: bool,
    lookback_days: int = 30,
) -> tuple[ExpenseForecast, ExpenseForecast]:
    """
    Returns (needs_forecast, wants_forecast).
    Caller must pass deduplicated transactions (bill proxies removed) [P4].
    `wants` uses Holt-Winters if trimmed history >= 14 days [P8].
    """
    needs_series = _build_daily(transactions, ["needs"],                  lookback_days, ref_date)
    wants_series = _build_daily(transactions, ["wants", "uncategorised"], lookback_days, ref_date)

    if is_cold_start:
        return _wma(needs_series, horizon), _wma(wants_series, horizon)

    needs_fc = _ses(needs_series, horizon)
    wants_fc = _holt_winters(wants_series, horizon)
    return needs_fc, wants_fc


# ==============================================================================
# SECTION 10 — Bill Overlay
# ==============================================================================

_RECURRENCE_DELTA: dict[str, relativedelta] = {
    "weekly":    relativedelta(weeks=1),
    "monthly":   relativedelta(months=1),
    "quarterly": relativedelta(months=3),
    "annual":    relativedelta(years=1),
}


def build_bill_overlay(
    bills:    list[dict],
    ref_date: date,
    horizon:  int,
) -> np.ndarray:
    """
    [P5] Recurring bills fetched regardless of paid status so early-paid
    recurring bills still project their next cycle into the window.
    """
    overlay = np.zeros(horizon, dtype=float)
    for bill in bills:
        amount   = float(bill["amount"])
        due      = bill["due_date"]
        is_paid  = bool(bill.get("is_paid"))
        period   = bill.get("recurrence_period")

        if not is_paid:
            idx = (due - ref_date).days
            if 0 <= idx < horizon:
                overlay[idx] += amount

        if bill.get("is_recurring") and period:
            delta = _RECURRENCE_DELTA.get(period)
            if delta:
                next_due = due + delta
                nidx     = (next_due - ref_date).days
                if 0 <= nidx < horizon:
                    overlay[nidx] += amount

    return overlay


# ==============================================================================
# SECTION 11 — Monte Carlo
# ==============================================================================

@dataclass
class MCResult:
    dates:                list[str]
    p10:                  list[float]
    p50:                  list[float]
    p90:                  list[float]
    prob_negative:        float
    expected_balance_14d: float


def run_monte_carlo(
    cb:                   float,
    income_paths:         np.ndarray,
    needs_fc:             ExpenseForecast,
    wants_fc:             ExpenseForecast,
    bill_overlay:         np.ndarray,
    daily_goal_deduction: float,
    n_iter:               int,
    horizon:              int,
    ref_date:             date,
    seed:                 int,
) -> MCResult:
    """[P10] Deterministic seed from user_id keeps fan chart stable across requests."""
    rng = np.random.default_rng(seed)

    needs_draws = rng.normal(
        needs_fc.forecast_mean, needs_fc.forecast_std, size=(n_iter, horizon)
    ).clip(min=0)
    wants_draws = rng.normal(
        wants_fc.forecast_mean, wants_fc.forecast_std, size=(n_iter, horizon)
    ).clip(min=0)

    net_daily = (
        income_paths
        - needs_draws
        - wants_draws
        - bill_overlay[np.newaxis, :]
        - daily_goal_deduction
    )

    balance_paths = cb + np.cumsum(net_daily, axis=1)

    p10 = np.percentile(balance_paths, 10, axis=0)
    p50 = np.percentile(balance_paths, 50, axis=0)
    p90 = np.percentile(balance_paths, 90, axis=0)

    final         = balance_paths[:, -1]
    prob_negative = float(np.mean(final < 0))
    expected_bal  = float(np.mean(final))

    dates = [
        (ref_date + timedelta(days=i + 1)).isoformat()
        for i in range(horizon)
    ]
    return MCResult(
        dates                = dates,
        p10                  = [round(float(v), 2) for v in p10],
        p50                  = [round(float(v), 2) for v in p50],
        p90                  = [round(float(v), 2) for v in p90],
        prob_negative        = round(prob_negative, 4),
        expected_balance_14d = round(expected_bal, 2),
    )


# ==============================================================================
# SECTION 12 — Snapshot Assembly
# ==============================================================================

def _pillar_scores(features: FeatureSet, mc: MCResult) -> dict:
    base      = 85.0 if features.income_type in ("salaried", "student") else 60.0
    trend_adj = {"surge": 10.0, "stable": 0.0, "dip": -20.0}[features.income_trend]
    inc_stab  = float(np.clip(base + trend_adj, 0, 100))

    # [P9] ADE floored at 0.01 — no division by zero, no negative ratio
    exp_ctrl = float(np.clip((features.EDE / features.ADE) * 100, 0, 100))

    if features.B == 0:
        bill_cov = 100.0
    elif features.CB >= 2 * features.B:
        bill_cov = 90.0
    elif features.CB >= features.B:
        bill_cov = 60.0
    elif features.CB >= 0.5 * features.B:
        bill_cov = 30.0
    else:
        bill_cov = 0.0

    goal_prog = float(np.clip((1.0 - mc.prob_negative) * 100, 0, 100))

    return {
        "income_stability": round(inc_stab,  1),
        "expense_control":  round(exp_ctrl,  1),
        "bill_coverage":    round(bill_cov,  1),
        "goal_progress":    round(goal_prog, 1),
    }


def _resilience(pillars: dict) -> tuple[int, str]:
    weights = {
        "income_stability": 0.30,
        "expense_control":  0.25,
        "bill_coverage":    0.25,
        "goal_progress":    0.20,
    }
    score = int(np.clip(round(sum(pillars[k] * w for k, w in weights.items())), 0, 100))
    s     = get_settings()
    label = (
        "STRONG"   if score >= s.RESILIENCE_STRONG   else
        "MODERATE" if score >= s.RESILIENCE_MODERATE else
        "BUILDING" if score >= s.RESILIENCE_BUILDING else
        "FRAGILE"
    )
    return score, label


def _risk_flags(features: FeatureSet, mc: MCResult) -> list[str]:
    flags: list[str] = []
    if features.is_cold_start or features.has_review_flags:
        flags.append("low_confidence")
    if features.income_trend == "dip":
        flags.append("income_dip")
    if features.B > 0 and features.CB < features.B:
        flags.append("bill_risk")
    if mc.prob_negative > 0.30:
        flags.append("negative_balance_risk")
    daily_burn = features.ADE + features.G
    if daily_burn > 0:
        survival = max(0.0, features.CB - features.B) / daily_burn
        if survival < 3:
            flags.append("critical_low_survival")
        elif survival < 7:
            flags.append("low_survival")
    if features.EDE / features.ADE < 0.30:
        flags.append("high_discretionary_spend")
    return flags


def _safe_to_spend(features: FeatureSet) -> float:
    reserved  = features.B + (features.G * features.days_to_income)
    spendable = max(0.0, features.CB - reserved)
    return round(spendable / features.days_to_income, 2)


def _survival_days(features: FeatureSet) -> float:
    daily_burn = features.ADE + features.G
    if daily_burn <= 0:
        return 999.0
    return round(max(0.0, features.CB - features.B) / daily_burn, 1)


def build_snapshot(
    features: FeatureSet,
    mc:       MCResult,
    ref_date: date,
    user_id:  UUID,
) -> dict:
    pillars              = _pillar_scores(features, mc)
    res_score, res_label = _resilience(pillars)
    flags                = _risk_flags(features, mc)

    return {
        "user_id":                 str(user_id),
        "snapshot_date":           ref_date.isoformat(),
        "wallet_balance":          round(features.CB,  2),
        "upcoming_bills_total":    round(features.B,   2),
        "avg_daily_expense":       round(features.ADE, 2),
        "essential_daily_expense": round(features.EDE, 2),
        "safe_to_spend_per_day":   _safe_to_spend(features),
        "survival_days":           _survival_days(features),
        "resilience_score":        res_score,
        "resilience_label":        res_label,
        "income_trend":            features.income_trend,
        "risk_flags":              flags,
        "balance_curve_14d": {
            "dates": mc.dates,
            "p10":   mc.p10,
            "p50":   mc.p50,
            "p90":   mc.p90,
        },
        "pillar_scores":  pillars,
        "_is_cold_start": features.is_cold_start,
    }


# ==============================================================================
# SECTION 13 — Core Pipeline (CPU-bound, runs in threadpool)  [P2]
# ==============================================================================

def _compute_prediction(
    user_id:      UUID,
    user:         dict,
    profile:      dict,
    transactions: list[dict],
    bills:        list[dict],
    goals:        list[dict],
) -> dict:
    """
    [P2] All statsmodels and NumPy heavy-compute lives in this plain sync
    function. The async route dispatches it via run_in_threadpool() so the
    FastAPI event loop is never blocked.
    """
    s           = get_settings()
    ref_date    = date.today()
    horizon     = s.FORECAST_HORIZON
    income_type = user["income_type"]

    # [P10] Deterministic seed from user identity
    seed = int(user_id.int % (2 ** 32))

    features = extract_features(
        transactions        = transactions,
        bills_in_window     = bills,
        goals               = goals,
        user_profile        = profile,
        income_type         = income_type,
        ref_date            = ref_date,
        cold_start_min_days = s.COLD_START_MIN_DAYS,
        forecast_horizon    = horizon,
    )

    income_paths = build_income_paths(
        income_type  = income_type,
        transactions = transactions,
        user_profile = profile,
        ref_date     = ref_date,
        horizon      = horizon,
        n_iter       = s.MC_ITERATIONS,
        seed         = seed,
    )

    # [P4] Deduplicate before feeding history to SES / Holt-Winters
    deduped_txs = deduplicate_bill_transactions(transactions, bills)

    needs_fc, wants_fc = model_expenses(
        transactions  = deduped_txs,
        ref_date      = ref_date,
        horizon       = horizon,
        is_cold_start = features.is_cold_start,
    )

    bill_overlay = build_bill_overlay(bills, ref_date, horizon)

    mc = run_monte_carlo(
        cb                   = features.CB,
        income_paths         = income_paths,
        needs_fc             = needs_fc,
        wants_fc             = wants_fc,
        bill_overlay         = bill_overlay,
        daily_goal_deduction = features.G,
        n_iter               = s.MC_ITERATIONS,
        horizon              = horizon,
        ref_date             = ref_date,
        seed                 = seed,
    )

    return build_snapshot(features, mc, ref_date, user_id)


# ==============================================================================
# SECTION 14 — FastAPI App + Routes
# ==============================================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_pool()
    logger.info("DB pool initialised.")
    yield
    await close_pool()
    logger.info("DB pool closed.")


app = FastAPI(
    title="CoachMint Prediction Engine",
    description=(
        "Pure statistical forecasting layer — no LLM / agentic logic. "
        "Produces probabilistic cash-flow snapshots (P10/P50/P90) and "
        "resilience scores for downstream agent consumption."
    ),
    version="3.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*", "X-API-KEY"],
)


@app.get("/health", response_model=HealthResponse, tags=["ops"])
async def health() -> HealthResponse:
    return HealthResponse(
        status="ok",
        version="3.0.0",
        timestamp=datetime.now(timezone.utc),
    )


@app.post(
    "/predict/{user_id}",
    response_model=PredictionResponse,
    summary="Run full prediction pipeline for one user",
    tags=["prediction"],
    dependencies=[Depends(verify_api_key)],   # [P3]
)
async def predict(user_id: UUID) -> PredictionResponse:
    """
    [P2] Heavy compute (_compute_prediction) dispatched to a thread via
    run_in_threadpool — statsmodels fitting and 5 000-path NumPy operations
    never block the async event loop.
    """
    pool = get_pool()
    s    = get_settings()

    # ── Fetch (async I/O) ─────────────────────────────────────────────────
    try:
        user = await db_fetch_user(pool, user_id)
        if not user:
            raise HTTPException(404, f"User {user_id} not found.")

        profile = await db_fetch_profile(pool, user_id)
        if not profile:
            raise HTTPException(404, f"Profile not found for user {user_id}.")
        if not profile.get("onboarding_complete"):
            raise HTTPException(422, "Onboarding incomplete — prediction unavailable.")

        ref_date = date.today()
        horizon  = s.FORECAST_HORIZON

        transactions = await db_fetch_transactions(pool, user_id, lookback_days=90)
        bills        = await db_fetch_bills(pool, user_id, ref_date, ref_date + timedelta(days=horizon))
        goals        = await db_fetch_goals(pool, user_id)

    except HTTPException:
        raise
    except Exception as exc:
        logger.exception("DB fetch failed for user %s: %s", user_id, exc)
        raise HTTPException(500, f"Data fetch error: {exc}") from exc

    # ── Compute (CPU-bound → threadpool)  [P2] ────────────────────────────
    try:
        snapshot = await run_in_threadpool(
            _compute_prediction,
            user_id, user, profile, transactions, bills, goals,
        )
    except Exception as exc:
        logger.exception("Compute failed for user %s: %s", user_id, exc)
        raise HTTPException(500, f"Prediction engine error: {exc}") from exc

    # ── Persist (async I/O) ───────────────────────────────────────────────
    try:
        await db_upsert_snapshot(pool, snapshot)
        logger.info(
            "Snapshot upserted | user=%s date=%s resilience=%s flags=%s",
            user_id, snapshot["snapshot_date"],
            snapshot["resilience_label"], snapshot["risk_flags"],
        )
    except Exception as exc:
        logger.exception("Upsert failed for user %s: %s", user_id, exc)
        raise HTTPException(500, f"Snapshot persist error: {exc}") from exc

    # ── Serialise ─────────────────────────────────────────────────────────
    curve   = snapshot["balance_curve_14d"]
    pillars = snapshot["pillar_scores"]

    return PredictionResponse(
        user_id                  = user_id,
        snapshot_date            = date.fromisoformat(snapshot["snapshot_date"]),
        wallet_balance           = snapshot["wallet_balance"],
        upcoming_bills_total     = snapshot["upcoming_bills_total"],
        avg_daily_expense        = snapshot["avg_daily_expense"],
        essential_daily_expense  = snapshot["essential_daily_expense"],
        safe_to_spend_per_day    = snapshot["safe_to_spend_per_day"],
        survival_days            = snapshot["survival_days"],
        resilience_score         = snapshot["resilience_score"],
        resilience_label         = snapshot["resilience_label"],
        income_trend             = snapshot["income_trend"],
        risk_flags               = snapshot["risk_flags"],
        balance_curve_14d        = BalanceCurve(**curve),
        pillar_scores            = PillarScores(**pillars),
        is_cold_start            = snapshot["_is_cold_start"],
        computed_at              = datetime.now(timezone.utc),
    )