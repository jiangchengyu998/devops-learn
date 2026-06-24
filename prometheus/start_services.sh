#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="${BASE_DIR:-/data/services}"
LOG_DIR="${LOG_DIR:-$BASE_DIR/logs}"
PID_DIR="${PID_DIR:-$BASE_DIR/pids}"
PROMETHEUS_DATA_DIR="${PROMETHEUS_DATA_DIR:-$BASE_DIR/prometheus-data}"
SERVICE_HOST="${SERVICE_HOST:-192.168.101.102}"
GRAFANA_HOME="${GRAFANA_HOME:-/usr/local/grafana-v11.4.0}"

mkdir -p "$LOG_DIR" "$PID_DIR" "$PROMETHEUS_DATA_DIR"

cd "$SCRIPT_DIR"
"$SCRIPT_DIR/stop_services.sh"

start_service() {
  local name="$1"
  shift

  echo "Starting $name..."
  nohup "$@" > "$LOG_DIR/$name.log" 2>&1 &
  echo "$!" > "$PID_DIR/$name.pid"
  echo "$name started with PID $(cat "$PID_DIR/$name.pid")."
}

start_service "prometheus" \
  prometheus \
  --config.file="$SCRIPT_DIR/prometheus.yml" \
  --storage.tsdb.path="$PROMETHEUS_DATA_DIR" \
  --web.listen-address="0.0.0.0:9090" \
  --web.external-url="http://$SERVICE_HOST:9090"
echo "prometheus web url: http://$SERVICE_HOST:9090"

start_service "alertmanager" \
  alertmanager \
  --config.file="$SCRIPT_DIR/alertmanager.yml" \
  --web.listen-address="0.0.0.0:9093" \
  --web.external-url="http://$SERVICE_HOST:9093"
echo "alertmanager web url: http://$SERVICE_HOST:9093"

if [ -x "$GRAFANA_HOME/bin/grafana-server" ]; then
  start_service "grafana" "$GRAFANA_HOME/bin/grafana-server" \
    --homepath "$GRAFANA_HOME"
  echo "grafana web url: http://$SERVICE_HOST:3000"
else
  echo "Skip grafana: $GRAFANA_HOME/bin/grafana-server not found or not executable."
fi

start_service "node_exporter" node_exporter
echo "node_exporter web url: http://$SERVICE_HOST:9100"

start_service "webhook" go run ./cmd/webhook
echo "webhook web url: http://$SERVICE_HOST:8081"

echo "All services started."
