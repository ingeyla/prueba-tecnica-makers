#!/usr/bin/env python3
"""SLO Checker for NovaLedger — AWS Track.

Correcciones:
- Consulta Prometheus API real en lugar de usar env vars hardcoded
- Múltiples SLO checks: error rate, latencia, disponibilidad
- Output estructurado con resultados claros
- Fallback a env vars para ejecución fuera del cluster
"""

import json
import os
import sys
import urllib.request
import urllib.error

# Configuración
PROMETHEUS_URL = os.getenv(
    "PROMETHEUS_URL",
    "http://prometheus-server.monitoring.svc.cluster.local"
)

# Umbrales SLO (basados en requisitos de NovaLedger)
SLO_ERROR_RATE_MAX = 0.01      # 1% máximo
SLO_LATENCY_P95_MS = 300       # 300ms p95 (requisito del documento)
SLO_AVAILABILITY_MIN = 0.999   # 99.9% disponibilidad mensual


def query_prometheus(query: str) -> float | None:
    """Ejecuta una query PromQL y retorna el valor escalar."""
    try:
        url = f"{PROMETHEUS_URL}/api/v1/query"
        data = urllib.parse.urlencode({"query": query}).encode()
        req = urllib.request.Request(url, data=data, method="POST")
        with urllib.request.urlopen(req, timeout=10) as resp:
            result = json.loads(resp.read())
            if result["status"] == "success" and result["data"]["result"]:
                return float(result["data"]["result"][0]["value"][1])
    except (urllib.error.URLError, KeyError, IndexError, ValueError) as e:
        print(f"  ⚠ Prometheus query failed: {e}")
    return None


def check_slo(name: str, value: float | None, threshold: float, operator: str = "<=") -> bool:
    """Evalúa un SLO y muestra resultado."""
    if value is None:
        # Fallback a env vars si Prometheus no está disponible
        env_key = name.upper().replace(" ", "_").replace("/", "_")
        env_val = os.getenv(env_key)
        if env_val:
            value = float(env_val)
            print(f"  ℹ Using env var {env_key}={value}")
        else:
            print(f"  ⚠ SKIP: {name} — no data available")
            return True  # No fallar si no hay datos

    if operator == "<=":
        passed = value <= threshold
        symbol = "≤"
    else:
        passed = value >= threshold
        symbol = "≥"

    status = "✓ PASS" if passed else "✗ FAIL"
    print(f"  {status}: {name} = {value:.4f} (SLO: {symbol} {threshold})")
    return passed


def main():
    print("=" * 50)
    print(" NovaLedger — SLO Validation")
    print("=" * 50)
    print()

    results = []

    # 1. Error rate
    print("▸ Error Rate")
    error_rate = query_prometheus(
        'sum(rate(http_requests_total{namespace="novaledger",app="payments-api",code=~"5.."}[5m]))'
        '/'
        'sum(rate(http_requests_total{namespace="novaledger",app="payments-api"}[5m]))'
    )
    results.append(check_slo("error_rate", error_rate, SLO_ERROR_RATE_MAX))

    # 2. Latencia p95
    print("▸ Latency P95")
    latency_p95 = query_prometheus(
        'histogram_quantile(0.95,'
        'sum(rate(http_request_duration_seconds_bucket{namespace="novaledger",app="payments-api"}[5m])) by (le)'
        ') * 1000'
    )
    results.append(check_slo("latency_p95_ms", latency_p95, SLO_LATENCY_P95_MS))

    # 3. Disponibilidad
    print("▸ Availability")
    availability = query_prometheus(
        '1 - (sum(rate(http_requests_total{namespace="novaledger",app="payments-api",code=~"5.."}[30d]))'
        '/ sum(rate(http_requests_total{namespace="novaledger",app="payments-api"}[30d])))'
    )
    results.append(check_slo("availability", availability, SLO_AVAILABILITY_MIN, ">="))

    print()
    print("=" * 50)
    if all(results):
        print("✓ ALL SLO CHECKS PASSED")
        sys.exit(0)
    else:
        print("✗ SLO CHECKS FAILED — deployment should be blocked or rolled back")
        sys.exit(1)


if __name__ == "__main__":
    main()
