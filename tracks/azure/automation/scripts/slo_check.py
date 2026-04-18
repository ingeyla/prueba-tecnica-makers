#!/usr/bin/env python3
import os
import sys

availability = float(os.getenv("AVAILABILITY", "99.0"))
mttr_minutes = int(os.getenv("MTTR_MINUTES", "45"))

if availability < 99.9:
    print(f"FAIL: availability below target: {availability}%")
    sys.exit(1)

if mttr_minutes > 30:
    print(f"FAIL: MTTR too high: {mttr_minutes} min")
    sys.exit(1)

print("PASS: SLO checks")
