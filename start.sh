#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="$ROOT/.run"
LOG_DIR="$RUN_DIR/logs"
PID_FILE="$RUN_DIR/gewu-agent.pid"
OUT_LOG="$LOG_DIR/backend.out.log"
ERR_LOG="$LOG_DIR/backend.err.log"
JAR="$ROOT/target/gewu-agent-0.0.1-SNAPSHOT.jar"
LOCAL_REPO="$ROOT/.m2/repository"

PORT=8080
BUILD=0

usage() {
  cat <<EOF
Usage:
  ./start.sh [--build] [--port 8080]

Options:
  --build, -b       Run Maven clean package before starting
  --port, -p PORT   Server port, default: 8080
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build|-b)
      BUILD=1
      shift
      ;;
    --port|-p)
      PORT="${2:-}"
      if [[ -z "$PORT" ]]; then
        echo "Missing port value." >&2
        exit 1
      fi
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

mkdir -p "$RUN_DIR" "$LOG_DIR" "$LOCAL_REPO"

load_env_file() {
  local env_file="$ROOT/.env"
  if [[ ! -f "$env_file" ]]; then
    return 0
  fi

  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
}

config_status() {
  local value="${1:-}"
  if [[ -z "$value" ]]; then
    printf 'not configured'
    return 0
  fi
  printf 'configured'
}

jar_needs_rebuild() {
  if [[ ! -f "$JAR" ]]; then
    return 0
  fi

  if find "$ROOT/pom.xml" "$ROOT/src/main" "$ROOT/src/test" -type f -newer "$JAR" 2>/dev/null | grep -q .; then
    return 0
  fi

  return 1
}

is_running() {
  local pid="$1"
  [[ -n "$pid" ]] && tasklist.exe //FI "PID eq $pid" //NH 2>/dev/null | grep -q "[[:space:]]$pid[[:space:]]"
}

if [[ -f "$PID_FILE" ]]; then
  OLD_PID="$(tr -d '[:space:]' < "$PID_FILE")"
  if [[ "$OLD_PID" =~ ^[0-9]+$ ]] && is_running "$OLD_PID"; then
    echo "Gewu Agent backend is already running. PID: $OLD_PID"
    echo "URL: http://localhost:$PORT"
    echo "Logs: $OUT_LOG"
    exit 0
  fi
  rm -f "$PID_FILE"
fi

load_env_file

java_major_version() {
  local java_exe="$1"
  [[ -x "$java_exe" ]] || return 1
  "$java_exe" -version 2>&1 | awk -F '"' '/version/ { split($2, a, "."); print a[1]; exit }'
}

resolve_jdk21() {
  local candidates=()

  if [[ -n "${JAVA_HOME:-}" ]]; then
    candidates+=("$JAVA_HOME")
  fi

  candidates+=(
    "$HOME/.jdks/ms-21.0.11"
    "$HOME/.jdks/openjdk-21"
  )

  local roots=(
    "/c/Program Files/Java"
    "/d/Program Files/Java"
    "/c/Program Files/Eclipse Adoptium"
    "/c/Program Files/Microsoft/jdk"
  )

  local root dir
  for root in "${roots[@]}"; do
    if [[ -d "$root" ]]; then
      while IFS= read -r -d '' dir; do
        candidates+=("$dir")
      done < <(find "$root" -maxdepth 1 -type d -iname '*21*' -print0 2>/dev/null)
    fi
  done

  local candidate java_exe version
  for candidate in "${candidates[@]}"; do
    java_exe="$candidate/bin/java.exe"
    version="$(java_major_version "$java_exe" || true)"
    if [[ "$version" == "21" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  echo "JDK 21 was not found. Install JDK 21 or set JAVA_HOME to a JDK 21 directory." >&2
  return 1
}

JDK_HOME="$(resolve_jdk21)"
JAVA_EXE="$JDK_HOME/bin/java.exe"
export JAVA_HOME="$JDK_HOME"
export PATH="$JAVA_HOME/bin:$PATH"

if [[ "$BUILD" == "1" ]] || jar_needs_rebuild; then
  echo "Building backend with JDK 21: $JAVA_HOME"
  mvn "-Dmaven.repo.local=$LOCAL_REPO" -q -DskipTests clean package
fi

if [[ ! -f "$JAR" ]]; then
  echo "Jar not found: $JAR" >&2
  echo "Run: ./start.sh --build" >&2
  exit 1
fi

: > "$OUT_LOG"
: > "$ERR_LOG"

GEWU_ROOT="$(cygpath -w "$ROOT")"
GEWU_JAVA_EXE="$(cygpath -w "$JAVA_EXE")"
GEWU_JAR="$(cygpath -w "$JAR")"
GEWU_OUT_LOG="$(cygpath -w "$OUT_LOG")"
GEWU_ERR_LOG="$(cygpath -w "$ERR_LOG")"
GEWU_PORT="$PORT"
START_CMD="$RUN_DIR/start-backend.cmd"
GEWU_START_CMD="$(cygpath -w "$START_CMD")"
CMD_DEEPSEEK_API_KEY="${DEEPSEEK_API_KEY:-}"
CMD_DEEPSEEK_BASE_URL="${DEEPSEEK_BASE_URL:-https://api.deepseek.com}"
CMD_DEEPSEEK_MODEL="${DEEPSEEK_MODEL:-deepseek-v4-flash}"
CMD_DEEPSEEK_TEMPERATURE="${DEEPSEEK_TEMPERATURE:-0.7}"

cat > "$START_CMD" <<EOF
@echo off
cd /d "$GEWU_ROOT"
set "DEEPSEEK_API_KEY=$CMD_DEEPSEEK_API_KEY"
set "DEEPSEEK_BASE_URL=$CMD_DEEPSEEK_BASE_URL"
set "DEEPSEEK_MODEL=$CMD_DEEPSEEK_MODEL"
set "DEEPSEEK_TEMPERATURE=$CMD_DEEPSEEK_TEMPERATURE"
"$GEWU_JAVA_EXE" -jar "$GEWU_JAR" --server.port=$GEWU_PORT > "$GEWU_OUT_LOG" 2> "$GEWU_ERR_LOG"
EOF

cmd.exe //d //c start "" //min "$GEWU_START_CMD" >/dev/null 2>&1

started=0
PID=""
for _ in {1..30}; do
  if grep -q "Started GewuAgentApplication" "$OUT_LOG" 2>/dev/null; then
    PID="$(sed -n 's/.* with PID \([0-9][0-9]*\).*/\1/p' "$OUT_LOG" | tail -n 1)"
    if [[ -z "$PID" ]]; then
      echo "Backend started, but Java PID could not be parsed from logs." >&2
      exit 1
    fi
    echo "$PID" > "$PID_FILE"
    started=1
    break
  fi
  sleep 1
done

if [[ "$started" != "1" ]]; then
  rm -f "$PID_FILE"
  echo "Gewu Agent backend failed to start. See logs:"
  echo "  $OUT_LOG"
  echo "  $ERR_LOG"
  exit 1
fi

echo "Gewu Agent backend started."
echo "PID: $PID"
echo "URL: http://localhost:$PORT"
echo "DeepSeek API key: $(config_status "${DEEPSEEK_API_KEY:-}")"
echo "Model: ${DEEPSEEK_MODEL:-deepseek-v4-flash}"
echo "Logs: $OUT_LOG"
echo
echo "Startup summary:"
grep -E "Starting GewuAgentApplication|Tomcat started|Started GewuAgentApplication" "$OUT_LOG" | tail -n 6
