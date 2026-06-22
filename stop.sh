#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$ROOT/.run/gewu-agent.pid"

if [[ ! -f "$PID_FILE" ]]; then
  echo "Gewu Agent backend is not running. PID file not found."
  exit 0
fi

PID="$(tr -d '[:space:]' < "$PID_FILE")"

if [[ ! "$PID" =~ ^[0-9]+$ ]]; then
  rm -f "$PID_FILE"
  echo "Removed invalid PID file."
  exit 0
fi

taskkill.exe //PID "$PID" //T //F >/dev/null 2>&1 || true
rm -f "$PID_FILE"

echo "Gewu Agent backend stopped. PID: $PID"
