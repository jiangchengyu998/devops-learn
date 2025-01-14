#!/bin/bash

BASE_DIR="/data/services"
LOG_DIR="$BASE_DIR/logs"
PID_DIR="$BASE_DIR/pids"

[ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR"
[ ! -d "$PID_DIR" ] && mkdir -p "$PID_DIR"

start_service() {
  local name=$1
  local cmd=$2

  echo "Starting $name..."
  nohup $cmd > "$LOG_DIR/$name.log" 2>&1 &
  echo $! > "$PID_DIR/$name.pid"
  echo "$name started with PID $(cat $PID_DIR/$name.pid)."
}

# 启动 Prometheus
start_service "prometheus" "prometheus --config.file=prometheus.yml --storage.tsdb.path=/data/prometheus --web.listen-address=0.0.0.0:9090 --web.external-url=http://192.168.101.102:9090"

# 启动 alertmanager
start_service "alertmanager" "alertmanager --config.file=alertmanager.yml --web.listen-address=0.0.0.0:9093 --web.external-url=http://192.168.101.102:9093"

echo "All services started."
