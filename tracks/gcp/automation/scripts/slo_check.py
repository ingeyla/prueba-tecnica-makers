#!/usr/bin/env python3
import os
import sys

error_budget_burn = float(os.getenv("ERROR_BUDGET_BURN", "1.5"))
queue_lag = int(os.getenv("QUEUE_LAG", "300"))

if error_budget_burn > 1.0:
    print(f"FAIL: error budget burn too high: {error_budget_burn}")
    sys.exit(1)

if queue_lag > 120:
    print(f"FAIL: queue lag too high: {queue_lag}s")
    sys.exit(1)

print("PASS: SLO checks")
