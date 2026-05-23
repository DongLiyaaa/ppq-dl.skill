"""
Shared configuration for ppq-dl.

Browser automation is handled by OpenClaw through the cdp-bridge MCP tools.
Python scripts in this package are limited to non-browser helpers and data persistence.
"""

import os

_skill_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_config_path = os.path.join(_skill_dir, "scripts", ".skillconfig")

_cfg = {}
if os.path.exists(_config_path):
    with open(_config_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                _cfg[key.strip()] = value.strip()

SKILL_DIR = _cfg.get("SKILL_DIR", _skill_dir)
CDP_BRIDGE_MCP = os.environ.get("CDP_BRIDGE_MCP", _cfg.get("CDP_BRIDGE_MCP", "cdp-bridge"))
CDP_BRIDGE_TRANSPORT = os.environ.get(
    "CDP_BRIDGE_TRANSPORT", _cfg.get("CDP_BRIDGE_TRANSPORT", "stdio")
)
CDP_BRIDGE_WS_PORT = os.environ.get("CDP_BRIDGE_WS_PORT", _cfg.get("CDP_BRIDGE_WS_PORT", "18765"))
CDP_BRIDGE_HTTP_PORT = os.environ.get(
    "CDP_BRIDGE_HTTP_PORT", _cfg.get("CDP_BRIDGE_HTTP_PORT", "8000")
)
CDP_BRIDGE_LOG_DIR = os.environ.get(
    "CDP_BRIDGE_LOG_DIR", _cfg.get("CDP_BRIDGE_LOG_DIR", os.path.join(os.path.expanduser("~"), ".ppq-dl", "logs"))
)


def _default_output():
    home = os.path.expanduser("~")
    docs = os.path.join(home, "Documents")
    return docs if os.path.isdir(docs) else home


OUTPUT_DIR = os.environ.get(
    "AMZ_OUTPUT_DIR",
    _cfg.get("AMZ_OUTPUT_DIR", os.path.join(_default_output(), "amazon-data")),
)
RANKING_DIR = os.environ.get(
    "AMZ_RANKING_DIR",
    _cfg.get("AMZ_RANKING_DIR", os.path.join(_default_output(), "keyword-rankings")),
)

SUGGEST_API = os.environ.get("AMZ_SUGGEST_API", "https://completion.amazon.com/api/2017/suggestions")
MARKETPLACE = os.environ.get("AMZ_MARKETPLACE", "ATVPDKIKX0DER")
