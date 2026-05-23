#!/bin/zsh
# Start a long-lived cdp-bridge HTTP service for more stable OpenClaw sessions.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_config.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log_ok()   { echo -e "${GREEN}[ok]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
log_err()  { echo -e "${RED}[error]${NC} $*"; }
log_step() { echo -e "\n${CYAN}==${NC} $*"; }

ensure_uvx() {
  if command -v uvx >/dev/null 2>&1; then
    return 0
  fi

  if [ -x "$HOME/.local/bin/uvx" ]; then
    export PATH="$HOME/.local/bin:$PATH"
    return 0
  fi

  return 1
}

port_listening() {
  lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

if ! ensure_uvx; then
  log_err "uvx not found. Run bash setup.sh first."
  exit 1
fi

mkdir -p "$CDP_BRIDGE_LOG_DIR"
LOG_FILE="$CDP_BRIDGE_LOG_DIR/cdp-bridge-http.log"

if port_listening "$CDP_BRIDGE_HTTP_PORT"; then
  log_ok "cdp-bridge HTTP is already listening on :$CDP_BRIDGE_HTTP_PORT"
  if port_listening "$CDP_BRIDGE_WS_PORT"; then
    log_ok "extension WebSocket is already listening on :$CDP_BRIDGE_WS_PORT"
  else
    log_warn "HTTP mode is up, but the extension WebSocket port :$CDP_BRIDGE_WS_PORT is not listening yet."
  fi
  echo "Log file: $LOG_FILE"
  exit 0
fi

log_step "Starting cdp-bridge streamable-http service"

cmd=(uvx cdp-bridge@latest --transport streamable-http --port "$CDP_BRIDGE_HTTP_PORT" --ws-port "$CDP_BRIDGE_WS_PORT")
if [ -n "$CDP_BRIDGE_TOKENS" ]; then
  cmd+=(--tokens "$CDP_BRIDGE_TOKENS")
fi

nohup "${cmd[@]}" > "$LOG_FILE" 2>&1 &
PID=$!

for _ in 1 2 3 4 5 6 7 8 9 10; do
  if port_listening "$CDP_BRIDGE_HTTP_PORT"; then
    break
  fi
  sleep 1
done

if ! port_listening "$CDP_BRIDGE_HTTP_PORT"; then
  log_err "cdp-bridge HTTP did not start successfully."
  echo "Log file: $LOG_FILE"
  exit 1
fi

log_ok "cdp-bridge HTTP started (pid $PID)"
log_ok "MCP endpoint: http://127.0.0.1:$CDP_BRIDGE_HTTP_PORT/mcp"
log_ok "Extension WebSocket port: $CDP_BRIDGE_WS_PORT"
echo "Log file: $LOG_FILE"
