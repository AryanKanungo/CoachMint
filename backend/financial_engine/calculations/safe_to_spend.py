"""
Core spending calculations: ADE, EDE, UB, MIN_RESERVE, SPD, SD.

────────────────────────────────────────────────────────────────
  ADE  = sum(needs + wants debits, last 30d)  /  30
         Average Daily Expense — full spending rate

  EDE  = sum(needs-only debits, last 30d)  /  30
         Essential Daily Expense — the absolute minimum floor
         (fuel, groceries, medicine, utilities, rent, EMI)

  UB   = sum(bill.amount for bills due on or before next_income_date)
         Upcoming Bills Total

  MIN_RESERVE  = 3 × EDE
         Three days of essential-only spending — always protected.
         Never included in what the user can spend.

  ASB  = CB − UB − MIN_RESERVE
         Available Spending Budget

  SPD  = ASB / ND      (ND = days to next income, minimum 1)
         Safe to Spend Per Day — the main dashboard number.

  SD   = (CB − UB) / ADE
         Survival Days — how many days money lasts at current rate.

Risk flags triggered by this module:
  HIGH_RISK      → SPD < 0        (can't cover bills + reserve)
  CRITICAL       → 0 ≤ SPD < EDE  (daily budget below essential needs)
  SHORTAGE_RISK  → SD  < ND       (won't survive to next income)
────────────────────────────────────────────────────────────────
"""

from datetime import date
from financial_engine.variables import Transaction, Bill


def calc_daily_averages(transactions: list[Transaction]) -> tuple[float, float]:
    """Returns (ADE, EDE). Savings and transfers excluded from both."""

    spending  = [
        t for t in transactions
        if t.type == "debit" and t.category_top not in ("savings", "transfer")
    ]
    essential = [t for t in spending if t.category_top == "needs"]

    ade = sum(t.amount for t in spending)   / 30
    ede = sum(t.amount for t in essential)  / 30

    return round(ade, 2), round(ede, 2)


def calc_upcoming_bills(bills: list[Bill], next_income_date: date) -> float:
    """Sum of unpaid bills due on or before next income date."""
    return round(
        sum(b.amount for b in bills if b.due_date <= next_income_date),
        2,
    )


def calc_spd(
    cb: float,
    ub: float,
    ede: float,
    days_to_income: int,
) -> tuple[float, float]:
    """
    Returns (SPD, MIN_RESERVE).
    days_to_income is floored at 1 to prevent division-by-zero on payday.
    """
    min_reserve = round(3 * ede, 2)
    asb         = cb - ub - min_reserve
    spd         = round(asb / max(1, days_to_income), 2)
    return spd, min_reserve


def calc_survival_days(cb: float, ub: float, ade: float) -> float:
    """
    SD = (CB − UB) / ADE.
    Returns 999.0 when ADE is zero (user has no spend history yet).
    """
    if ade <= 0:
        return 999.0
    return round((cb - ub) / ade, 1)
