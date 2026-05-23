#!/bin/zsh
# Shared configuration for ppq-dl.

export SKILL_DIR="${SKILL_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

# cdp-bridge MCP settings. The MCP server itself is configured through OpenClaw.
export CDP_BRIDGE_MCP="${CDP_BRIDGE_MCP:-cdp-bridge}"
export CDP_BRIDGE_TRANSPORT="${CDP_BRIDGE_TRANSPORT:-stdio}"
export CDP_BRIDGE_WS_PORT="${CDP_BRIDGE_WS_PORT:-18765}"
export CDP_BRIDGE_HTTP_PORT="${CDP_BRIDGE_HTTP_PORT:-8000}"
export CDP_BRIDGE_LOG_DIR="${CDP_BRIDGE_LOG_DIR:-$HOME/.ppq-dl/logs}"

export AMZ_OUTPUT_DIR="${AMZ_OUTPUT_DIR:-$HOME/Documents/amazon-data}"
export AMZ_RANKING_DIR="${AMZ_RANKING_DIR:-$HOME/Documents/keyword-rankings}"

export AMZ_SUGGEST_API="${AMZ_SUGGEST_API:-https://completion.amazon.com/api/2017/suggestions}"
export AMZ_MARKETPLACE="${AMZ_MARKETPLACE:-ATVPDKIKX0DER}"
export NO_PROXY="${NO_PROXY:-127.0.0.1,localhost,amazon.com,amazonaws.com,media-amazon.com,images-amazon.com,completion.amazon.com}"
