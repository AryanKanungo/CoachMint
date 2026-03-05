"""
Bill Guard — projects whether each bill will be covered on its due date.

Formula per bill:
    projected_balance = CB − (ADE × days_until_due) − sum(other bills)
    at_risk           = projected_balance < bill.amount

"other bills" = every other unpaid bill (not the one being evaluated).
This prevents double-counting when evaluating one bill at a time.

days_until_due is floored at 0 (bill already overdue → worst case projection).

Feeds:
  → risk_flags: BILL_RISK  (if any bill is at_risk)
  → Flutter bill tracker screen (per-bill status)
  → Agentic layer: bill name, shortfall, days remaining for alert text
"""

from datetime import date
from financial_engine.variables import Bill, BillGuardResult


def calc_bill_guard(
    cb: float,
    bills: list[Bill],
    ade: float,
    today: date,
) -> list[BillGuardResult]:

    results = []

    for bill in bills:
        days_until_due = max(0, (bill.due_date - today).days)
        other_bills    = sum(b.amount for b in bills if b.name != bill.name)
        projected      = cb - (ade * days_until_due) - other_bills

        results.append(BillGuardResult(
            name                     = bill.name,
            amount                   = bill.amount,
            due_date                 = bill.due_date,
            projected_balance_at_due = round(projected, 2),
            at_risk                  = projected < bill.amount,
        ))

    return results
