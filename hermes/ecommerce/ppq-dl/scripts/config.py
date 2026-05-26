"""
Shared configuration for Hermes ppq-dl.

Browser automation is handled by Hermes through browser_* tools and optional CDP
attachment. Python scripts in this package are limited to non-browser helpers and
data persistence.
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
HERMES_BROWSER_DEBUG_PORT = os.environ.get(
    "HERMES_BROWSER_DEBUG_PORT", _cfg.get("HERMES_BROWSER_DEBUG_PORT", "9222")
)
HERMES_BROWSER_PROFILE_DIR = os.environ.get(
    "HERMES_BROWSER_PROFILE_DIR",
    _cfg.get("HERMES_BROWSER_PROFILE_DIR", os.path.join(os.path.expanduser("~"), ".hermes", "chrome-debug")),
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
