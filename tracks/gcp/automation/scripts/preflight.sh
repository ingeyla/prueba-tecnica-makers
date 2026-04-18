#!/usr/bin/env bash
set -euo pipefail

for cmd in terraform kubectl gcloud python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing dependency: $cmd"
    exit 1
  fi
done

echo "gcp preflight checks OK"
