#!/bin/zsh
# Diagnose Hermes browser prerequisites for ppq-dl.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_config.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log_ok()   { echo -e "${GREEN}[ok]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
log_err()  { echo -e "${RED}[error]${NC} $*"; }
log_step() { echo -e "\n${CYAN}==${NC} $*"; }

log_step "Hermes"
if command -v hermes >/dev/null 2>&1; then
  log_ok "hermes: $(command -v hermes)"
else
  log_err "hermes not found in PATH"
  exit 1
fi

CFG_DUMP="$(hermes config 2>/dev/null || true)"
if printf '%s\n' "$CFG_DUMP" | rg -q '\bbrowser\b'; then
  log_ok "browser toolset mentioned in Hermes config"
else
  log_warn "browser toolset not detected in Hermes config output"
fi

if printf '%s\n' "$CFG_DUMP" | rg -q '\bterminal\b'; then
  log_ok "terminal toolset mentioned in Hermes config"
else
  log_warn "terminal toolset not detected in Hermes config output"
fi

log_step "Local CDP endpoint"
if curl -fsS "http://127.0.0.1:${HERMES_BROWSER_DEBUG_PORT}/json/version" >/tmp/ppq_dl_hermes_cdp.json 2>/dev/null; then
  log_ok "CDP endpoint reachable: http://127.0.0.1:${HERMES_BROWSER_DEBUG_PORT}"
  if command -v jq >/dev/null 2>&1; then
    WS_URL="$(jq -r '.webSocketDebuggerUrl // empty' /tmp/ppq_dl_hermes_cdp.json)"
  else
    WS_URL="$(python3 - <<'PY'
import json
try:
    with open('/tmp/ppq_dl_hermes_cdp.json') as f:
        print(json.load(f).get('webSocketDebuggerUrl', ''))
except Exception:
    print('')
PY
)"
  fi
  if [ -n "$WS_URL" ]; then
    log_ok "webSocketDebuggerUrl: $WS_URL"
  else
    log_warn "json/version returned no webSocketDebuggerUrl"
  fi
else
  log_warn "CDP endpoint is not reachable on port ${HERMES_BROWSER_DEBUG_PORT}"
fi

rm -f /tmp/ppq_dl_hermes_cdp.json

echo ""
echo "Recommended next actions:"
echo "  1. If no CDP endpoint is reachable, run:"
echo "     bash scripts/launch_local_chrome.sh"
echo "  2. Then open Hermes CLI and run:"
echo "     /browser connect"
echo "  3. Or persist the websocket URL with:"
echo "     hermes config set browser.cdp_url ws://127.0.0.1:${HERMES_BROWSER_DEBUG_PORT}/devtools/browser/<id>"
