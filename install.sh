#!/usr/bin/env bash
# learnFromClaude — manual installer (fallback).
#
# The recommended install is via Claude Code's plugin system:
#   /plugin marketplace add github:pathakcodes/learnFromClaude
#   /plugin install learn-from-claude@learnFromClaude
#
# This script is for users who want to install without the plugin system — it
# copies the runtime files to ~/.claude/learnFromClaude and registers hooks
# directly in ~/.claude/settings.json.

set -euo pipefail

INSTALL_DIR="${LFC_INSTALL_DIR:-$HOME/.claude/learnFromClaude}"
BIN_DIR="${LFC_BIN_DIR:-$HOME/.local/bin}"
SETTINGS="$HOME/.claude/settings.json"
REPO_RAW="https://raw.githubusercontent.com/pathakcodes/learnFromClaude/main/plugins/learn-from-claude"

if [ -t 1 ]; then
  B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; X=$'\033[0m'
else B= G= Y= R= X=; fi
say()  { printf '%s%s%s\n' "$B" "$*" "$X"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$X" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$X" "$*"; }
die()  { printf '%s✗%s %s\n' "$R" "$X" "$*" >&2; exit 1; }

say "learnFromClaude manual installer"

# Prereqs
command -v jq      >/dev/null 2>&1 || die "jq is required (macOS: brew install jq)"
command -v python3 >/dev/null 2>&1 || die "python3 is required"
command -v curl    >/dev/null 2>&1 || die "curl is required"
command -v claude  >/dev/null 2>&1 || warn "claude CLI not found — install Claude Code first"
ok "jq $(jq --version), python3 $(python3 --version | awk '{print $2}')"

# Source: local clone or remote
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/plugins/learn-from-claude/server.py" ]; then
  SRC="local"; SRC_DIR="$SCRIPT_DIR/plugins/learn-from-claude"
  say "Installing from local clone"
else
  SRC="remote"; say "Installing from $REPO_RAW"
fi

mkdir -p "$INSTALL_DIR" "$INSTALL_DIR/hooks" "$INSTALL_DIR/sessions" "$BIN_DIR"

fetch() {
  # $1 = repo-relative path, $2 = destination
  if [ "$SRC" = "local" ]; then cp "$SRC_DIR/$1" "$2"
  else curl -fsSL "$REPO_RAW/$1" -o "$2"; fi
}

fetch server.py          "$INSTALL_DIR/server.py"
fetch dashboard.html     "$INSTALL_DIR/dashboard.html"
fetch hooks/capture.sh   "$INSTALL_DIR/hooks/capture.sh"
fetch hooks/summarize.sh "$INSTALL_DIR/hooks/summarize.sh"
chmod +x "$INSTALL_DIR/server.py" "$INSTALL_DIR/hooks/"*.sh

# Preserve user-edited CONFIG.md; keep a read-only default for reset.
fetch CONFIG.md "$INSTALL_DIR/CONFIG.default.md"
chmod 444 "$INSTALL_DIR/CONFIG.default.md"
if [ ! -f "$INSTALL_DIR/CONFIG.md" ]; then
  cp "$INSTALL_DIR/CONFIG.default.md" "$INSTALL_DIR/CONFIG.md"
  chmod 644 "$INSTALL_DIR/CONFIG.md"
  ok "installed default CONFIG.md"
else
  ok "preserved existing CONFIG.md"
fi
[ -f "$INSTALL_DIR/flashcards.json" ] || echo "[]" > "$INSTALL_DIR/flashcards.json"
ok "files installed to $INSTALL_DIR"

# CLI launcher
ln -sf "$INSTALL_DIR/server.py" "$BIN_DIR/learnFromClaude"
ok "CLI: $BIN_DIR/learnFromClaude"
case ":$PATH:" in *":$BIN_DIR:"*) : ;; *) warn "add $BIN_DIR to PATH" ;; esac

# Merge hooks into settings.json (idempotent)
mkdir -p "$(dirname "$SETTINGS")"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
CAP="bash $INSTALL_DIR/hooks/capture.sh"
SUM="bash $INSTALL_DIR/hooks/summarize.sh"
jq --arg cap "$CAP" --arg sum "$SUM" '
  .hooks = (.hooks // {}) |
  .hooks.PostToolUse = ((.hooks.PostToolUse // [])
    | map(select((.hooks // []) | map(.command) | any(test("learnFromClaude|learning-coach")) | not))
    + [{matcher: "", hooks: [{type: "command", command: $cap}]}]) |
  .hooks.SessionEnd = ((.hooks.SessionEnd // [])
    | map(select((.hooks // []) | map(.command) | any(test("learnFromClaude|learning-coach")) | not))
    + [{matcher: "", hooks: [{type: "command", command: $sum}]}])
' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
ok "hooks registered in $SETTINGS"

printf '\n'; say "Installation complete. Run: learnFromClaude"
