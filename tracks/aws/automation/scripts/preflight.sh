#!/usr/bin/env bash
# Preflight checks — AWS Track
# Verifica que todas las dependencias y configuraciones están listas
# antes de un despliegue.
#
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

check() {
  local name="$1"
  shift
  if "$@" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} $name"
  else
    echo -e "${RED}✗${NC} $name"
    ERRORS=$((ERRORS + 1))
  fi
}

echo " NovaLedger — Preflight Checks"
echo ""

# --- Herramientas requeridas ---
echo "▸ Checking required tools..."
for cmd in terraform kubectl python3 aws docker; do
  check "$cmd installed" command -v "$cmd"
done

echo ""

# --- AWS credentials ---
echo "▸ Checking AWS credentials..."
check "AWS identity configured" aws sts get-caller-identity

# --- Cluster EKS ---
echo ""
echo "▸ Checking Kubernetes cluster..."
check "kubectl context set" kubectl config current-context
check "cluster reachable" kubectl cluster-info

# --- Namespace ---
echo ""
echo "▸ Checking namespace..."
check "novaledger namespace exists" kubectl get namespace novaledger

# --- Secrets de la aplicación ---
echo ""
echo "▸ Checking application secrets..."
check "payments-api-db secret exists" kubectl -n novaledger get secret payments-api-db
check "risk-worker-queue secret exists" kubectl -n novaledger get secret risk-worker-queue

# --- Terraform state ---
echo ""
echo "▸ Checking Terraform..."
check "terraform initialized" test -d tracks/aws/iac/terraform/.terraform

echo ""
if [ $ERRORS -gt 0 ]; then
  echo -e "${RED}PREFLIGHT FAILED: $ERRORS check(s) failed${NC}"
  exit 1
else
  echo -e "${GREEN}PREFLIGHT PASSED: All checks OK${NC}"
  exit 0
fi
