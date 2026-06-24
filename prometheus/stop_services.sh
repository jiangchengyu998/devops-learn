#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${BASE_DIR:-/data/services}"
PID_DIR="${PID_DIR:-$BASE_DIR/pids}"

stop_service() {
  local name="$1"
  local pid_file="$PID_DIR/$name.pid"

  if [ -f "$pid_file" ]; then
    local pid
    pid="$(cat "$pid_file")"
    if kill -0 "$pid" 2>/dev/null; then
      echo "Stopping $name (PID: $pid)..."
      kill "$pid"
      sleep 2
      if kill -0 "$pid" 2>/dev/null; then
        echo "$name did not stop, forcing..."
        kill -9 "$pid"
      fi
      echo "$name stopped."
      rm -f "$pid_file"
    else
      echo "No such process for $name. Cleaning up PID file."
      rm -f "$pid_file"
    fi
  else
    echo "No PID file found for $name. It may not be running."
  fi
}

stop_service "prometheus"
stop_service "alertmanager"
stop_service "grafana"
stop_service "gargana"
stop_service "node_exporter"
stop_service "webhook"

echo "All services stopped."
