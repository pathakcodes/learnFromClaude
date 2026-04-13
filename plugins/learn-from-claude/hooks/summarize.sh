#!/usr/bin/env bash
# learnFromClaude — SessionEnd hook.
# Reads the user's per-session tool log and the user-editable CONFIG.md, asks a
# headless `claude -p` to extract learning cards per the config, and appends
# them to flashcards.json. Runs detached so session exit is never blocked.
#
# CONFIG.md is injected verbatim into the prompt — edit in plain English to
# change what gets extracted and how many cards per session.

set -u

[ "${LEARN_FROM_CLAUDE_SKIP:-0}" = "1" ] && exit 0
[ "${LEARNING_COACH_SKIP:-0}" = "1" ] && exit 0  # legacy

# User data lives outside the plugin dir so upgrades don't wipe cards/sessions.
BASE="${LFC_DATA_DIR:-$HOME/.claude/learnFromClaude}"
SESSIONS_DIR="$BASE/sessions"
CARDS="$BASE/flashcards.json"
CONFIG="$BASE/CONFIG.md"
LOG="$BASE/summarize.log"
mkdir -p "$SESSIONS_DIR"

# First-run bootstrap: copy the plugin-shipped default CONFIG into the user
# dir so they have something to edit. CLAUDE_PLUGIN_ROOT is set by Claude Code.
if [ ! -f "$CONFIG" ] && [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "$CLAUDE_PLUGIN_ROOT/CONFIG.md" ]; then
  cp "$CLAUDE_PLUGIN_ROOT/CONFIG.md" "$CONFIG"
fi

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)

if [ -z "$SESSION_ID" ]; then
  SESSION_FILE=$(ls -t "$SESSIONS_DIR"/*.jsonl 2>/dev/null | head -1)
else
  SESSION_FILE="$SESSIONS_DIR/$SESSION_ID.jsonl"
fi

[ -z "${SESSION_FILE:-}" ] || [ ! -s "$SESSION_FILE" ] && exit 0

# Honor min_session_events from CONFIG.md; default 3.
MIN=3
if [ -f "$CONFIG" ]; then
  VAL=$(grep -E '^\s*-\s+\*\*min_session_events\*\*' "$CONFIG" | grep -oE '[0-9]+' | head -1)
  [ -n "${VAL:-}" ] && MIN="$VAL"
fi
LINES=$(wc -l < "$SESSION_FILE" | tr -d ' ')
[ "$LINES" -lt "$MIN" ] && exit 0

# Honor max_session_events; default 300.
MAX=300
if [ -f "$CONFIG" ]; then
  VAL=$(grep -E '^\s*-\s+\*\*max_session_events\*\*' "$CONFIG" | grep -oE '[0-9]+' | head -1)
  [ -n "${VAL:-}" ] && MAX="$VAL"
fi

# Detach: summarization can take 10-30s; session exit shouldn't wait.
(
  SUMMARY=$(head -"$MAX" "$SESSION_FILE" | jq -r '"\(.tool)\t\(.payload // "")"' 2>/dev/null)
  [ -z "$SUMMARY" ] && exit 0

  if [ -f "$CONFIG" ]; then
    CONFIG_BODY=$(cat "$CONFIG")
  else
    CONFIG_BODY="(no CONFIG.md — use sensible defaults: 3-5 cards, skip trivial commands, JSON array output only.)"
  fi

  PROMPT="You are the learnFromClaude session summarizer. Your job is to read a
log of a Claude Code session (TSV: tool<TAB>payload) and emit learning cards.

You MUST follow the config below. It is the contract — it sets the card count,
what to extract, what to skip, the tone, and the exact output schema. If the
session contains nothing worth carding, output an empty array [].

=================== BEGIN CONFIG ===================
$CONFIG_BODY
==================== END CONFIG ====================

=================== SESSION LOG (TSV) ===================
$SUMMARY
==================== END SESSION LOG ====================

Emit a JSON array of learning cards per the Output contract. No prose, no fences."

  # Nested claude call — skip flag prevents capture.sh from logging its tools.
  RESPONSE=$(LEARN_FROM_CLAUDE_SKIP=1 LEARNING_COACH_SKIP=1 \
    claude -p "$PROMPT" --output-format text 2>>"$LOG")

  # Strip accidental code fences.
  CLEAN=$(printf '%s' "$RESPONSE" | sed -e 's/^```json//' -e 's/^```//' -e 's/```$//' | jq -c '.' 2>/dev/null)
  if [ -z "$CLEAN" ]; then
    echo "[$(date)] empty/invalid response for $SESSION_FILE" >> "$LOG"
    exit 0
  fi

  NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  SID=$(basename "$SESSION_FILE" .jsonl)
  [ -f "$CARDS" ] || echo "[]" > "$CARDS"

  TMP=$(mktemp)
  jq --argjson new "$CLEAN" --arg now "$NOW" --arg sid "$SID" '
    . + ($new | map(. + {
      id: ((now | tostring) + "-" + (.title // "card") | gsub("[^a-zA-Z0-9-]"; "-")[0:80]),
      session_id: $sid,
      created_at: $now,
      liked: false,
      reviewed_count: 0
    }))
  ' "$CARDS" > "$TMP" 2>>"$LOG" && mv "$TMP" "$CARDS" || rm -f "$TMP"

  NEW_COUNT=$(printf '%s' "$CLEAN" | jq 'length' 2>/dev/null || echo 0)
  echo "[$(date)] added $NEW_COUNT cards from $SID (config: min=$MIN max=$MAX)" >> "$LOG"
) >/dev/null 2>&1 &

disown 2>/dev/null || true
exit 0
