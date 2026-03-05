"""
Goal Progress + Emergency Fund.

Goal progress formula:
    remaining            = target_amount − saved_amount
    daily_surplus        = max(0, SPD − avg_daily_spend_7d)
    days_to_goal         = remaining / daily_surplus   (999 if no surplus)
    daily_surplus_needed = remaining / days_until_deadline  (if deadline set)
    on_track             = days_to_goal ≤ days_until_deadline

Emergency fund (always exists, auto-calculated):
    ef_target   = 3 × ADE        ← one month of average spending as buffer
    ef_saved    = max(0, CB − UB − ADE)
                  money sitting above the 1-day danger line
    ef_progress = ef_saved / ef_target   (capped at 1.0)

ef_progress feeds:
  → Resilience score Pillar P5
  → Emergency fund progress bar in Flutter
"""

from datetime import date
from financial_engine.variables import Goal, GoalResult


def calc_goal_progress(
    goals:             list[Goal],
    spd:               float,
    avg_daily_spend_7d: float,
    today:             date,
) -> list[GoalResult]:

    daily_surplus = max(0.0, spd - avg_daily_spend_7d)
    results       = []

    for goal in goals:
        remaining = max(0.0, goal.target_amount - goal.saved_amount)

        if daily_surplus > 0:
            days_to_goal = remaining / daily_surplus
        else:
            days_to_goal = 999.0

        if goal.deadline:
            days_available       = max(1, (goal.deadline - today).days)
            daily_surplus_needed = remaining / days_available
            on_track             = days_to_goal <= days_available
        else:
            daily_surplus_needed = 0.0   # no deadline = no pressure
            on_track             = True

        results.append(GoalResult(
            name                 = goal.name,
            target               = goal.target_amount,
            saved                = goal.saved_amount,
            remaining            = round(remaining, 2),
            daily_surplus_needed = round(daily_surplus_needed, 2),
            days_to_goal         = round(days_to_goal, 1),
            on_track             = on_track,
            is_emergency_fund    = goal.is_emergency_fund,
        ))

    return results


def calc_emergency_fund(
    cb:  float,
    ub:  float,
    ade: float,
) -> tuple[float, float]:
    """
    Returns (ef_saved, ef_progress).
    ef_target = 3 × ADE.
    ef_saved  = money above the 1-day danger line (CB − UB − ADE).
    """
    ef_target   = 3 * ade
    ef_saved    = max(0.0, cb - ub - ade)
    ef_progress = min(1.0, ef_saved / ef_target) if ef_target > 0 else 0.0

    return round(ef_saved, 2), round(ef_progress, 3)
