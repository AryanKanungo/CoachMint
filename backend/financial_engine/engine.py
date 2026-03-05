"""
Financial Engine — main entry point.

    run_engine(EngineInput) → EngineOutput

Zero DB calls. Zero API calls. Pure math only.
The router assembles EngineInput from Supabase, passes it here,
then writes EngineOutput back to Supabase.

Execution order:
    1.  CB   — resolve wallet balance
    2.  UB   — sum upcoming bills
    3.  ADE, EDE — daily spending averages
    4.  ND   — days to next income
    5.  SPD, MIN_RESERVE — safe to spend per day
    6.  SD   — survival days
    7.  Bill Guard — per-bill risk projection
    8.  Income trend + CV — volatility
    9.  Emergency fund — progress toward 3×ADE target
    10. Goal progress — per goal
    11. Resilience score — 5 pillars
    12. Risk flags — what the agentic layer acts on
"""

import datetime
from financial_engine.variables import EngineInput, EngineOutput

from financial_engine.calculations.wallet        import resolve_balance
from financial_engine.calculations.safe_to_spend import (
    calc_daily_averages,
    calc_upcoming_bills,
    calc_spd,
    calc_survival_days,
)
from financial_engine.calculations.bill_guard    import calc_bill_guard
from financial_engine.calculations.income_trend  import calc_income_trend
from financial_engine.calculations.goals         import calc_goal_progress, calc_emergency_fund
from financial_engine.calculations.resilience    import calc_resilience


def run_engine(inp: EngineInput) -> EngineOutput:

    today = datetime.date.today()

    # ── 1. wallet balance (CB) ────────────────────────────────────────────────
    cb = resolve_balance(inp.starting_balance, inp.transactions_30d)

    # ── 2. upcoming bills total (UB) ──────────────────────────────────────────
    ub = calc_upcoming_bills(inp.bills, inp.next_income_date)

    # ── 3. daily averages (ADE, EDE) ──────────────────────────────────────────
    ade, ede = calc_daily_averages(inp.transactions_30d)

    # ── 4. days to next income (ND) ───────────────────────────────────────────
    nd = max(1, (inp.next_income_date - today).days)

    # ── 5. safe to spend per day (SPD) + min reserve ──────────────────────────
    spd, min_reserve = calc_spd(cb, ub, ede, nd)

    # ── 6. survival days (SD) ─────────────────────────────────────────────────
    sd = calc_survival_days(cb, ub, ade)

    # ── 7. bill guard ─────────────────────────────────────────────────────────
    bill_guard = calc_bill_guard(cb, inp.bills, ade, today)

    # ── 8. income trend + volatility ─────────────────────────────────────────
    income_trend, income_cv = calc_income_trend(inp.transactions_30d)

    # ── 9. emergency fund ─────────────────────────────────────────────────────
    _, ef_progress = calc_emergency_fund(cb, ub, ade)

    # ── 10. goal progress ─────────────────────────────────────────────────────
    # avg daily spend over the most recent 7 days (needs + wants only)
    seven_days_ago     = str(today - datetime.timedelta(days=7))
    recent_spend       = [
        t for t in inp.transactions_30d
        if t.type == "debit"
        and t.category_top not in ("savings", "transfer")
        and t.transaction_date[:10] >= seven_days_ago
    ]
    avg_daily_spend_7d = sum(t.amount for t in recent_spend) / 7

    goal_results = calc_goal_progress(inp.goals, spd, avg_daily_spend_7d, today)

    # ── 11. resilience score ──────────────────────────────────────────────────
    resilience_score, resilience_label, pillar_scores = calc_resilience(
        survival_days  = sd,
        days_to_income = nd,
        bill_guard     = bill_guard,
        transactions   = inp.transactions_30d,
        income_cv      = income_cv,
        ef_progress    = ef_progress,
        spd            = spd,
    )

    # ── 12. risk flags ────────────────────────────────────────────────────────
    # These drive the agentic layer's alert decisions.
    # Evaluated in priority order.
    risk_flags: list[str] = []

    if spd < 0:
        risk_flags.append("HIGH_RISK")        # CB can't cover UB + MIN_RESERVE

    if 0 <= spd < ede:
        risk_flags.append("CRITICAL")          # SPD less than essential daily needs

    if sd < nd:
        risk_flags.append("SHORTAGE_RISK")     # won't survive to next income at current rate

    if any(b.at_risk for b in bill_guard):
        risk_flags.append("BILL_RISK")         # at least one bill projected to bounce

    if income_trend == "dip":
        risk_flags.append("INCOME_DIP")        # this week < 70% of 4-week average

    # OVERSPEND is checked at request time by the router (today's spend vs SPD)
    # not here — it depends on the time of day the engine runs

    return EngineOutput(
        wallet_balance          = round(cb, 2),
        upcoming_bills_total    = ub,
        avg_daily_expense       = ade,
        essential_daily_expense = ede,
        min_reserve             = min_reserve,
        safe_to_spend_per_day   = spd,
        survival_days           = sd,
        resilience_score        = resilience_score,
        resilience_label        = resilience_label,
        pillar_scores           = pillar_scores,
        income_trend            = income_trend,
        income_cv               = income_cv,
        risk_flags              = risk_flags,
        bill_guard              = bill_guard,
        goal_results            = goal_results,
        ef_progress             = ef_progress,
    )
