#!/usr/bin/env bash
# learnFromClaude — uninstaller.
#
# Removes the CLI launcher, strips our hook entries from ~/.claude/settings.json,
# and (optionally) deletes the install directory + saved cards.
#
# Your cards and session history are kept by default. Pass --purge to delete them.

set -euo pipefail

INSTALL_DIR="${LFC_INSTALL_DIR:-$HOME/.claude/learnFromClaude}"
BIN_DIR="${LFC_BIN_DIR:-$HOME/.local/bin}"
SETTINGS="$HOME/.claude/settings.json"
PURGE=0

for arg in "$@"; do
  case "$arg" in
    --purge) PURGE=1 ;;
    -h|--help)
      echo "Usage: uninstall.sh [--purge]"
      echo "  --purge   also delete $INSTALL_DIR (cards, sessions, logs)"
      exit 0 ;;
  esac
done

if [ -t 1 ]; then
  G=$'\033[32m'; Y=$'\033[33m'; X=$'\033[0m'
else
  G= Y= X=
fi
ok()   { printf '  %s✓%s %s\n' "$G" "$X" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$X" "$*"; }

# Remove CLI launcher
if [ -L "$BIN_DIR/learnFromClaude" ] || [ -f "$BIN_DIR/learnFromClaude" ]; then
  rm -f "$BIN_DIR/learnFromClaude"
  ok "removed $BIN_DIR/learnFromClaude"
fi

# Strip hook entries from settings.json, keeping everything else intact.
if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
  BACKUP="$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
  cp "$SETTINGS" "$BACKUP"
  jq '
    if .hooks then
      .hooks.PostToolUse = ((.hooks.PostToolUse // [])
        | map(select((.hooks // []) | map(.command) | any(test("learnFromClaude|learning-coach")) | not))) |
      .hooks.SessionEnd = ((.hooks.SessionEnd // [])
        | map(select((.hooks // []) | map(.command) | any(test("learnFromClaude|learning-coach")) | not)))
    else . end
  ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  ok "stripped hook entries from $SETTINGS"
  ok "backup: $BACKUP"
fi

if [ "$PURGE" = "1" ]; then
  if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    ok "removed $INSTALL_DIR"
  fi
  # Also remove the legacy symlink if it exists.
  [ -L "$HOME/.claude/learning-coach" ] && rm -f "$HOME/.claude/learning-coach" && ok "removed legacy compat symlink"
else
  warn "kept $INSTALL_DIR (cards and sessions). Re-run with --purge to delete."
fi

echo "Uninstalled."
