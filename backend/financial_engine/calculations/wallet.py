"""
Wallet Balance Resolution (CB — Current Balance).

Priority 1 — SMS balance (most accurate):
    The most recent transaction that carries wallet_balance_after
    (i.e. the bank SMS included "Avl Bal: ₹X") is used directly.
    This reflects the real bank balance at that moment.

Priority 2 — wallet math (fallback):
    starting_balance  +  sum(all credits)  −  sum(all debits)
    Used when no SMS has included a balance yet (early users).

The engine always calls this first. CB from here feeds every other calculation.
"""

from financial_engine.variables import Transaction


def resolve_balance(
    starting_balance: float,
    transactions: list[Transaction],
) -> float:

    # Priority 1: most recent transaction with an SMS balance
    for txn in sorted(transactions, key=lambda t: t.transaction_date, reverse=True):
        if txn.wallet_balance_after is not None:
            return txn.wallet_balance_after

    # Priority 2: wallet math from starting balance
    credits = sum(t.amount for t in transactions if t.type == "credit")
    debits  = sum(t.amount for t in transactions if t.type == "debit")
    return starting_balance + credits - debits
