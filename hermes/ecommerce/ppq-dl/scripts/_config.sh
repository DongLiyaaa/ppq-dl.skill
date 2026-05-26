#!/bin/zsh
# Shared configuration for Hermes ppq-dl.

export SKILL_DIR="${SKILL_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

export HERMES_BROWSER_DEBUG_PORT="${HERMES_BROWSER_DEBUG_PORT:-9222}"
export HERMES_BROWSER_PROFILE_DIR="${HERMES_BROWSER_PROFILE_DIR:-$HOME/.hermes/chrome-debug}"

export AMZ_OUTPUT_DIR="${AMZ_OUTPUT_DIR:-$HOME/Documents/amazon-data}"
export AMZ_RANKING_DIR="${AMZ_RANKING_DIR:-$HOME/Documents/keyword-rankings}"

export AMZ_SUGGEST_API="${AMZ_SUGGEST_API:-https://completion.amazon.com/api/2017/suggestions}"
export AMZ_MARKETPLACE="${AMZ_MARKETPLACE:-ATVPDKIKX0DER}"
export NO_PROXY="${NO_PROXY:-127.0.0.1,localhost,amazon.com,amazonaws.com,media-amazon.com,images-amazon.com,completion.amazon.com}"
