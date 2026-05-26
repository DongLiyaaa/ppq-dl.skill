#!/bin/zsh
# Launch a local Chromium-family browser with a CDP debug port for Hermes.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_config.sh"

find_browser() {
  if [ "$(uname -s)" = "Darwin" ]; then
    local candidates=(
      "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
      "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
      "/Applications/Chromium.app/Contents/MacOS/Chromium"
      "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
    )
  else
    local candidates=(
      "$(command -v google-chrome 2>/dev/null || true)"
      "$(command -v google-chrome-stable 2>/dev/null || true)"
      "$(command -v chromium-browser 2>/dev/null || true)"
      "$(command -v chromium 2>/dev/null || true)"
      "$(command -v brave-browser 2>/dev/null || true)"
      "$(command -v microsoft-edge 2>/dev/null || true)"
    )
  fi

  local candidate
  for candidate in "${candidates[@]}"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

if curl -fsS "http://127.0.0.1:${HERMES_BROWSER_DEBUG_PORT}/json/version" >/dev/null 2>&1; then
  echo "Chrome CDP already available at http://127.0.0.1:${HERMES_BROWSER_DEBUG_PORT}"
  exit 0
fi

BROWSER_BIN="$(find_browser || true)"
if [ -z "$BROWSER_BIN" ]; then
  echo "No supported Chrome/Brave/Chromium/Edge binary found."
  exit 1
fi

mkdir -p "$HERMES_BROWSER_PROFILE_DIR"

"$BROWSER_BIN" \
  --remote-debugging-port="$HERMES_BROWSER_DEBUG_PORT" \
  --user-data-dir="$HERMES_BROWSER_PROFILE_DIR" \
  --no-first-run \
  --no-default-browser-check >/dev/null 2>&1 &

sleep 2

if curl -fsS "http://127.0.0.1:${HERMES_BROWSER_DEBUG_PORT}/json/version" >/dev/null 2>&1; then
  echo "Started browser with CDP port ${HERMES_BROWSER_DEBUG_PORT}"
  echo "Profile dir: $HERMES_BROWSER_PROFILE_DIR"
else
  echo "Browser launch attempted, but CDP endpoint is still unavailable."
  exit 1
fi
