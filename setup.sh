#!/bin/zsh
# ppq-dl setup
# Configures cdp-bridge MCP for OpenClaw and prepares local data directories.

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

ensure_uvx() {
  if command -v uvx >/dev/null 2>&1; then
    return 0
  fi

  if [ -x "$HOME/.local/bin/uvx" ]; then
    export PATH="$HOME/.local/bin:$PATH"
    return 0
  fi

  log_warn "uvx not found. Trying the official uv installer first..."
  if command -v curl >/dev/null 2>&1; then
    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
      export PATH="$HOME/.local/bin:$PATH"
    fi
  fi

  if command -v uvx >/dev/null 2>&1 || [ -x "$HOME/.local/bin/uvx" ]; then
    export PATH="$HOME/.local/bin:$PATH"
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    log_warn "Official uv installer did not expose uvx. Trying Homebrew as a fallback..."
    brew install uv
  fi

  command -v uvx >/dev/null 2>&1
}

echo "=========================================="
echo " ppq-dl — Setup"
echo "=========================================="

log_step "Step 1: Check runtime"

if ! command -v python3 >/dev/null 2>&1; then
  log_err "python3 not found. Install Python 3 first."
  exit 1
fi
log_ok "python3: $(command -v python3)"

if ! command -v jq >/dev/null 2>&1; then
  log_warn "jq not found. Some JSON inspection commands will be less convenient."
else
  log_ok "jq: $(command -v jq)"
fi

if ! ensure_uvx; then
  log_err "uvx is still unavailable."
  echo "  Preferred install path:"
  echo "    curl -LsSf https://astral.sh/uv/install.sh | sh"
  echo "  Optional fallback on macOS/Linux with Homebrew:"
  echo "    brew install uv"
  echo "  After installation, rerun: bash setup.sh"
  exit 1
fi
log_ok "uvx: $(command -v uvx)"

if [ "$CDP_BRIDGE_TRANSPORT" != "stdio" ] && [ "$CDP_BRIDGE_TRANSPORT" != "streamable-http" ]; then
  log_err "Unsupported CDP_BRIDGE_TRANSPORT=$CDP_BRIDGE_TRANSPORT"
  echo "  Allowed values: stdio | streamable-http"
  exit 1
fi

ensure_exec_bit "$SCRIPT_DIR/scripts/run_cdp_bridge_http.sh"
ensure_exec_bit "$SCRIPT_DIR/scripts/cdp_bridge_doctor.sh"

log_step "Step 2: Fetch cdp-bridge extension source"

VENDOR_DIR="$SCRIPT_DIR/.vendor"
CDP_REPO_DIR="$VENDOR_DIR/cdp-bridge-mcp"
mkdir -p "$VENDOR_DIR"

if [ -d "$CDP_REPO_DIR/.git" ]; then
  git -C "$CDP_REPO_DIR" pull --ff-only
else
  git clone --depth 1 https://github.com/Unagi-cq/cdp-bridge-mcp.git "$CDP_REPO_DIR"
fi

EXT_DIR="$CDP_REPO_DIR/src/cdp_bridge/tmwd_cdp_bridge"
if [ ! -d "$EXT_DIR" ]; then
  log_err "cdp-bridge extension directory not found: $EXT_DIR"
  exit 1
fi
log_ok "cdp-bridge extension: $EXT_DIR"

log_step "Step 3: Configure OpenClaw MCP"

if [ "$CDP_BRIDGE_TRANSPORT" = "streamable-http" ]; then
  mkdir -p "$CDP_BRIDGE_LOG_DIR"
  "$SCRIPT_DIR/scripts/run_cdp_bridge_http.sh"
  MCP_CONFIG="{\"type\":\"streamableHttp\",\"url\":\"http://127.0.0.1:${CDP_BRIDGE_HTTP_PORT}/mcp\"}"
else
  MCP_CONFIG='{"command":"uvx","args":["cdp-bridge@latest"]}'
fi

if command -v openclaw >/dev/null 2>&1; then
  openclaw mcp set cdp-bridge "$MCP_CONFIG"
  log_ok "OpenClaw MCP configured: cdp-bridge"
else
  log_warn "openclaw command not found. Add this MCP manually:"
  echo "  cdp-bridge => $MCP_CONFIG"
fi

log_step "Step 4: Verify cdp-bridge command"

uvx cdp-bridge@latest --help >/dev/null
log_ok "uvx cdp-bridge@latest is callable"

log_step "Step 5: Prepare data directories"

mkdir -p "$AMZ_OUTPUT_DIR" "$AMZ_RANKING_DIR"
log_ok "Data directory: $AMZ_OUTPUT_DIR"
log_ok "Ranking directory: $AMZ_RANKING_DIR"

cat > "$SCRIPT_DIR/scripts/.skillconfig" <<EOF
# ppq-dl auto-generated config
SKILL_DIR=$SCRIPT_DIR
CDP_BRIDGE_MCP=$CDP_BRIDGE_MCP
CDP_BRIDGE_TRANSPORT=$CDP_BRIDGE_TRANSPORT
CDP_BRIDGE_WS_PORT=$CDP_BRIDGE_WS_PORT
CDP_BRIDGE_HTTP_PORT=$CDP_BRIDGE_HTTP_PORT
CDP_BRIDGE_LOG_DIR=$CDP_BRIDGE_LOG_DIR
AMZ_OUTPUT_DIR=$AMZ_OUTPUT_DIR
AMZ_RANKING_DIR=$AMZ_RANKING_DIR
EOF

echo ""
echo "Next steps:"
echo "  1. Open Chrome/Chromium: chrome://extensions/"
echo "  2. Enable Developer Mode."
echo "  3. Load unpacked extension:"
echo "     $EXT_DIR"
if [ "$CDP_BRIDGE_TRANSPORT" = "streamable-http" ]; then
  echo "  4. Keep the HTTP bridge alive via:"
  echo "     bash scripts/run_cdp_bridge_http.sh"
  echo "  5. Open a new OpenClaw session and confirm the MCP tool list contains browser_get_tabs."
else
  echo "  4. Restart OpenClaw gateway or open a new OpenClaw session."
  echo "  5. Confirm the MCP tool list contains browser_get_tabs or other cdp-bridge browser tools."
fi
echo "  6. If the bridge disconnects later, run:"
echo "     bash scripts/cdp_bridge_doctor.sh"
