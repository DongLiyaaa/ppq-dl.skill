#!/bin/zsh
# Hermes setup for ppq-dl.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/scripts/_config.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log_ok()   { echo -e "${GREEN}[ok]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
log_err()  { echo -e "${RED}[error]${NC} $*"; }
log_step() { echo -e "\n${CYAN}==${NC} $*"; }

ensure_exec_bit() {
  chmod +x "$1"
}

echo "=========================================="
echo " ppq-dl — Hermes Setup"
echo "=========================================="

log_step "Step 1: Check runtime"

if ! command -v python3 >/dev/null 2>&1; then
  log_err "python3 not found. Install Python 3 first."
  exit 1
fi
log_ok "python3: $(command -v python3)"

if ! command -v hermes >/dev/null 2>&1; then
  log_err "hermes not found in PATH."
  echo "  Install Hermes first, then rerun: bash setup.sh"
  exit 1
fi
log_ok "hermes: $(command -v hermes)"

if ! command -v curl >/dev/null 2>&1; then
  log_err "curl not found."
  exit 1
fi
log_ok "curl: $(command -v curl)"

if ! command -v jq >/dev/null 2>&1; then
  log_warn "jq not found. Doctor checks will still work, but JSON inspection is less convenient."
else
  log_ok "jq: $(command -v jq)"
fi

ensure_exec_bit "$SCRIPT_DIR/scripts/install_local.sh"
ensure_exec_bit "$SCRIPT_DIR/scripts/install_hermes.sh"
ensure_exec_bit "$SCRIPT_DIR/scripts/launch_local_chrome.sh"
ensure_exec_bit "$SCRIPT_DIR/scripts/hermes_browser_doctor.sh"

log_step "Step 2: Prepare data directories"

mkdir -p "$AMZ_OUTPUT_DIR" "$AMZ_RANKING_DIR" "$HERMES_BROWSER_PROFILE_DIR"
log_ok "Data directory: $AMZ_OUTPUT_DIR"
log_ok "Ranking directory: $AMZ_RANKING_DIR"
log_ok "Browser debug profile: $HERMES_BROWSER_PROFILE_DIR"

cat > "$SCRIPT_DIR/scripts/.skillconfig" <<EOF
# ppq-dl Hermes auto-generated config
SKILL_DIR=$SCRIPT_DIR
HERMES_BROWSER_DEBUG_PORT=$HERMES_BROWSER_DEBUG_PORT
HERMES_BROWSER_PROFILE_DIR=$HERMES_BROWSER_PROFILE_DIR
AMZ_OUTPUT_DIR=$AMZ_OUTPUT_DIR
AMZ_RANKING_DIR=$AMZ_RANKING_DIR
AMZ_SUGGEST_API=$AMZ_SUGGEST_API
AMZ_MARKETPLACE=$AMZ_MARKETPLACE
EOF

log_step "Step 3: Inspect Hermes toolsets"

CFG_DUMP="$(hermes config 2>/dev/null || true)"
if printf '%s\n' "$CFG_DUMP" | rg -q '\bbrowser\b'; then
  log_ok "Hermes config already mentions browser toolset"
else
  log_warn "Browser toolset was not detected in Hermes config output."
fi

if printf '%s\n' "$CFG_DUMP" | rg -q '\bterminal\b'; then
  log_ok "Hermes config already mentions terminal toolset"
else
  log_warn "Terminal toolset was not detected in Hermes config output."
fi

echo ""
echo "Preferred installer:"
echo "  bash scripts/install_hermes.sh"
echo "  bash scripts/install_hermes.sh --launch-browser"
echo ""
echo "Recommended toolsets command:"
echo "  hermes config set toolsets '[\"hermes-cli\", \"browser\", \"terminal\"]'"
echo ""
echo "Next steps:"
echo "  1. In Hermes CLI, run: /browser connect"
echo "  2. Or start a local debug browser first:"
echo "     bash scripts/launch_local_chrome.sh"
echo "  3. Optional persistent CDP config:"
echo "     hermes config set browser.cdp_url ws://127.0.0.1:${HERMES_BROWSER_DEBUG_PORT}/devtools/browser/<id>"
echo "  4. Health check:"
echo "     bash scripts/hermes_browser_doctor.sh"
