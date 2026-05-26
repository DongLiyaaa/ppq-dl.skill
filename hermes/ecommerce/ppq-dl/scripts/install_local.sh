#!/bin/zsh
# Symlink the local Hermes ppq-dl skill into ~/.hermes/skills/.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HERMES_HOME_DIR="${HERMES_HOME:-$HOME/.hermes}"
TARGET_DIR="$HERMES_HOME_DIR/skills/ecommerce/ppq-dl"

mkdir -p "$HERMES_HOME_DIR/skills/ecommerce"

if [ "$SKILL_DIR" = "$TARGET_DIR" ]; then
  echo "Skill already lives at $TARGET_DIR"
  exit 0
fi

rm -rf "$TARGET_DIR"
ln -s "$SKILL_DIR" "$TARGET_DIR"

echo "Installed Hermes skill symlink:"
echo "  $TARGET_DIR -> $SKILL_DIR"
