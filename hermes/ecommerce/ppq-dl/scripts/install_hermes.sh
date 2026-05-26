#!/bin/zsh
# Install ppq-dl into Hermes and write the minimal config needed for browser use.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/_config.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log_ok()   { echo -e "${GREEN}[ok]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
log_err()  { echo -e "${RED}[error]${NC} $*"; }
log_step() { echo -e "\n${CYAN}==${NC} $*"; }

LAUNCH_BROWSER=0

while [ $# -gt 0 ]; do
  case "$1" in
    --launch-browser)
      LAUNCH_BROWSER=1
      ;;
    --help|-h)
      echo "Usage: bash scripts/install_hermes.sh [--launch-browser]"
      exit 0
      ;;
    *)
      log_err "Unknown argument: $1"
      echo "Usage: bash scripts/install_hermes.sh [--launch-browser]"
      exit 1
      ;;
  esac
  shift
done

if ! command -v hermes >/dev/null 2>&1; then
  log_err "hermes not found in PATH."
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  log_err "python3 not found in PATH."
  exit 1
fi

log_step "Step 1: Install skill into ~/.hermes/skills"
bash "$SCRIPT_DIR/install_local.sh"
log_ok "Hermes skill symlink ready"

log_step "Step 2: Merge Hermes toolsets"

HERMES_HOME_DIR="${HERMES_HOME:-$HOME/.hermes}"
CONFIG_PATH="$HERMES_HOME_DIR/config.yaml"
mkdir -p "$HERMES_HOME_DIR"

MERGED_TOOLSETS="$(
python3 - "$CONFIG_PATH" <<'PY'
import json
import re
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
required = ["hermes-cli", "browser", "terminal"]
existing = []

if config_path.exists():
    lines = config_path.read_text(encoding="utf-8").splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        inline = re.match(r"^toolsets:\s*\[(.*)\]\s*$", line)
        if inline:
            raw = inline.group(1).strip()
            if raw:
                for part in raw.split(","):
                    value = part.strip().strip('"').strip("'")
                    if value:
                        existing.append(value)
            break
        if re.match(r"^toolsets:\s*$", line):
            j = i + 1
            while j < len(lines):
                nxt = lines[j]
                if re.match(r"^\S", nxt):
                    break
                m = re.match(r"^\s*-\s*(.+?)\s*$", nxt)
                if not m:
                    break
                value = m.group(1).strip()
                if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
                    value = value[1:-1]
                existing.append(value)
                j += 1
            break
        i += 1

merged = []
for item in existing + required:
    if item and item not in merged:
        merged.append(item)

print(json.dumps(merged))
PY
)"

hermes config set toolsets "$MERGED_TOOLSETS" >/dev/null
log_ok "Hermes toolsets merged: $MERGED_TOOLSETS"

log_step "Step 3: Run skill setup"
bash "$SKILL_DIR/setup.sh"
log_ok "Skill setup completed"

if [ "$LAUNCH_BROWSER" = "1" ]; then
  log_step "Step 4: Launch local debug browser"
  bash "$SCRIPT_DIR/launch_local_chrome.sh"
fi

log_step "Step 5: Detect local CDP websocket"

CDP_JSON="$(mktemp)"
if curl -fsS "http://127.0.0.1:${HERMES_BROWSER_DEBUG_PORT}/json/version" > "$CDP_JSON" 2>/dev/null; then
  WS_URL="$(
  python3 - "$CDP_JSON" <<'PY'
import json
import sys
try:
    with open(sys.argv[1], encoding="utf-8") as f:
        data = json.load(f)
    print(data.get("webSocketDebuggerUrl", ""))
except Exception:
    print("")
PY
  )"
  if [ -n "$WS_URL" ]; then
    hermes config set browser.cdp_url "$WS_URL" >/dev/null
    log_ok "browser.cdp_url updated: $WS_URL"
  else
    log_warn "CDP endpoint responded but did not include webSocketDebuggerUrl"
  fi
else
  log_warn "No local CDP endpoint detected on 127.0.0.1:${HERMES_BROWSER_DEBUG_PORT}"
fi
rm -f "$CDP_JSON"

echo ""
echo "Next steps:"
echo "  1. Start Hermes in the terminal."
echo "  2. If browser.cdp_url was not auto-written, run:"
echo "     /browser connect"
echo "  3. Health check:"
echo "     bash \"$SKILL_DIR/scripts/hermes_browser_doctor.sh\""
