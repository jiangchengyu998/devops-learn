#!/usr/bin/env bash
set -euo pipefail

URL="${URL:-http://192.168.101.102:8083/hello}"
COUNT="${COUNT:-10000}"
SLEEP_SECONDS="${SLEEP_SECONDS:-0.1}"

for (( i=1; i<=COUNT; i++ ));
do
  curl --fail --show-error --silent "$URL"
  echo ""
  echo "sleep ${SLEEP_SECONDS}s"
  sleep "$SLEEP_SECONDS"
done
