"""
Mock test — run the engine with no DB, no API, no config needed.

    cd backend
    python test_mock.py

Scenarios covered in this mock:
  ✓ Income dip (this week 50% below average → INCOME_DIP flag)
  ✓ Bill at risk (electricity due in 3 days, will be short → BILL_RISK)
  ✓ Jio recharge safely covered
  ✓ Emergency fund goal in progress
  ✓ Phone goal behind deadline
  ✓ All 5 resilience pillars calculated
  ✓ SMS balance used as CB (Priority 1)
"""

import sys, os
sys.path.insert(0, os.path.dirname(__file__))

from datetime import date, timedelta
from financial_engine.variables import EngineInput, Transaction, Bill, Goal
from financial_engine.engine    import run_engine

today = date.today()

mock_input = EngineInput(
    user_id          = "mock-raju-gig-001",
    starting_balance = 6000.0,
    next_income_date = today + timedelta(days=9),
    expected_income  = 5500.0,
    income_frequency = "irregular",

    transactions_30d = [

        # ── income (4 weeks — last week is a dip) ────────────────────────────
        Transaction("credit", 4500.0, "income", None, str(today - timedelta(days=27))),
        Transaction("credit", 4200.0, "income", None, str(today - timedelta(days=20))),
        Transaction("credit", 4800.0, "income", None, str(today - timedelta(days=13))),
        Transaction("credit", 1900.0, "income", None, str(today - timedelta(days=3))),  # dip

        # ── needs (fuel, groceries, medicine) ────────────────────────────────
        Transaction("debit", 350.0, "needs", None,   str(today - timedelta(days=8))),
        Transaction("debit", 280.0, "needs", None,   str(today - timedelta(days=6))),
        Transaction("debit", 190.0, "needs", None,   str(today - timedelta(days=4))),
        Transaction("debit", 420.0, "needs", 3800.0, str(today - timedelta(days=1))),  # SMS balance included

        # ── wants (food delivery, entertainment) ─────────────────────────────
        Transaction("debit", 390.0, "wants", None,   str(today - timedelta(days=7))),
        Transaction("debit", 210.0, "wants", None,   str(today - timedelta(days=5))),
        Transaction("debit", 175.0, "wants", None,   str(today - timedelta(days=3))),
        Transaction("debit", 480.0, "wants", None,   str(today - timedelta(days=2))),
    ],

    bills = [
        Bill("Electricity",  1800.0, today + timedelta(days=3),  True),   # at risk
        Bill("Jio Recharge",  299.0, today + timedelta(days=14), True),   # covered
    ],

    goals = [
        Goal("Emergency Fund", 4500.0,  750.0, None,                          True),
        Goal("New Phone",      8000.0, 1200.0, today + timedelta(days=45),    False),
    ],
)

# ── run engine ────────────────────────────────────────────────────────────────
out = run_engine(mock_input)

# ── print ─────────────────────────────────────────────────────────────────────
W = 58

def line(label, value):
    print(f"  {label:<32} {value}")

print()
print("─" * W)
print("  CoachMint — Engine Output (Mock: Raju, Gig Worker)")
print("─" * W)

print()
print("  WALLET")
line("Current Balance (CB)",          f"₹{out.wallet_balance}")
line("Upcoming Bills (UB)",           f"₹{out.upcoming_bills_total}")
line("Avg Daily Expense (ADE)",       f"₹{out.avg_daily_expense}")
line("Essential Daily Expense (EDE)", f"₹{out.essential_daily_expense}")
line("Min Reserve  (3 × EDE)",        f"₹{out.min_reserve}")

print()
print("  CORE OUTPUTS")
line("Safe to Spend / Day (SPD)",     f"₹{out.safe_to_spend_per_day}")
line("Survival Days (SD)",            f"{out.survival_days} days")

print()
print("  RESILIENCE")
line("Score",                         f"{out.resilience_score} / 100")
line("Label",                         out.resilience_label)
for k, v in out.pillar_scores.items():
    line(f"  {k}", v)

print()
print("  INCOME")
line("Trend",                         out.income_trend)
line("Volatility (CV)",               out.income_cv)
line("Emergency Fund Progress",       f"{round(out.ef_progress * 100)}%")

print()
if out.risk_flags:
    print(f"  ⚠  Risk Flags: {', '.join(out.risk_flags)}")
else:
    print("  ✅ No risk flags")

print()
print("  BILL GUARD")
print("  " + "─" * (W - 2))
for b in out.bill_guard:
    status = "⚠  AT RISK" if b.at_risk else "✅ covered"
    due    = str(b.due_date)
    print(f"  {b.name:<20} ₹{b.amount:<8} due {due}  proj ₹{b.projected_balance_at_due:<10} {status}")

print()
print("  GOAL PROGRESS")
print("  " + "─" * (W - 2))
for g in out.goal_results:
    track = "✅ on track" if g.on_track else "⚠  BEHIND"
    print(f"  {g.name:<22} ₹{g.saved}/₹{g.target}   {g.days_to_goal} days to goal   {track}")

print("─" * W)
print()
