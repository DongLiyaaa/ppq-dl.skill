#!/bin/zsh
# Diagnose common cdp-bridge disconnect states for ppq-dl.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_config.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log_ok()   { echo -e "${GREEN}[ok]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
log_err()  { echo -e "${RED}[error]${NC} $*"; }
log_step() { echo -e "\n${CYAN}==${NC} $*"; }

port_listening() {
  lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

echo "=========================================="
echo " ppq-dl — cdp-bridge doctor"
echo "=========================================="

log_step "Current configuration"
echo "transport: $CDP_BRIDGE_TRANSPORT"
echo "ws-port:   $CDP_BRIDGE_WS_PORT"
echo "http-port: $CDP_BRIDGE_HTTP_PORT"
echo "logs:      $CDP_BRIDGE_LOG_DIR"

log_step "Binary checks"
if command -v python3 >/dev/null 2>&1; then
  log_ok "python3: $(command -v python3)"
else
  log_err "python3 not found"
fi

if command -v uvx >/dev/null 2>&1; then
  log_ok "uvx: $(command -v uvx)"
elif [ -x "$HOME/.local/bin/uvx" ]; then
  export PATH="$HOME/.local/bin:$PATH"
  log_ok "uvx: $HOME/.local/bin/uvx"
else
  log_err "uvx not found. Run bash setup.sh first."
fi

if command -v openclaw >/dev/null 2>&1; then
  log_ok "openclaw: $(command -v openclaw)"
  if openclaw mcp show cdp-bridge >/dev/null 2>&1; then
    log_ok "openclaw mcp show cdp-bridge: ok"
  else
    log_warn "OpenClaw does not currently show a cdp-bridge MCP entry."
  fi
else
  log_warn "openclaw command not found in PATH"
fi

log_step "Port checks"
if [ "$CDP_BRIDGE_TRANSPORT" = "streamable-http" ]; then
  if port_listening "$CDP_BRIDGE_HTTP_PORT"; then
    log_ok "HTTP MCP listener is up on :$CDP_BRIDGE_HTTP_PORT"
  else
    log_warn "HTTP MCP listener is down on :$CDP_BRIDGE_HTTP_PORT"
  fi
else
  if port_listening "$CDP_BRIDGE_HTTP_PORT"; then
    log_warn "HTTP MCP listener is up on :$CDP_BRIDGE_HTTP_PORT, but the skill is configured for stdio."
  else
    log_ok "No standalone HTTP MCP listener detected, which is expected for stdio mode."
  fi
fi

if port_listening "$CDP_BRIDGE_WS_PORT"; then
  log_ok "Extension WebSocket listener is up on :$CDP_BRIDGE_WS_PORT"
else
  log_warn "Extension WebSocket listener is down on :$CDP_BRIDGE_WS_PORT"
fi

log_step "Extension source"
EXT_DIR="$SKILL_DIR/.vendor/cdp-bridge-mcp/src/cdp_bridge/tmwd_cdp_bridge"
if [ -d "$EXT_DIR" ]; then
  log_ok "extension dir: $EXT_DIR"
else
  log_warn "extension dir not found at $EXT_DIR"
fi

log_step "Recommended recovery"
if [ "$CDP_BRIDGE_TRANSPORT" = "streamable-http" ]; then
  if ! port_listening "$CDP_BRIDGE_HTTP_PORT"; then
    echo "1. Run: bash scripts/run_cdp_bridge_http.sh"
    echo "2. Keep Chrome open and wait 5-10 seconds for the extension to auto-reconnect."
    echo "3. In OpenClaw, retry browser_get_tabs."
  else
    echo "1. Wait 5-10 seconds for the extension to auto-reconnect."
    echo "2. In OpenClaw, retry browser_get_tabs."
    echo "3. If still broken, reload the extension and rerun this doctor."
  fi
else
  echo "1. Retry browser_get_tabs once and wait 5-10 seconds; the extension auto-reconnects after the backend appears."
  echo "2. If tools stay disconnected, open a new OpenClaw session or restart the OpenClaw gateway."
  echo "3. If disconnects are frequent, switch to long-lived HTTP mode:"
  echo "   CDP_BRIDGE_TRANSPORT=streamable-http bash setup.sh"
  echo "   bash scripts/run_cdp_bridge_http.sh"
fi
