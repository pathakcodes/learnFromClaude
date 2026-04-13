#!/usr/bin/env bash
# learnFromClaude — PostToolUse hook.
# Appends a compact record of each tool invocation to a per-session JSONL log.
# Non-blocking, best-effort: any error is swallowed so we never disrupt Claude Code.

set -u

# Skip when invoked recursively by the summarizer's own `claude -p` call.
[ "${LEARN_FROM_CLAUDE_SKIP:-0}" = "1" ] && exit 0
[ "${LEARNING_COACH_SKIP:-0}" = "1" ] && exit 0  # legacy env name

BASE="$HOME/.claude/learnFromClaude"
SESSIONS_DIR="$BASE/sessions"
mkdir -p "$SESSIONS_DIR" 2>/dev/null || exit 0

INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
[ -z "$SESSION_ID" ] || [ "$SESSION_ID" = "null" ] && SESSION_ID="unknown"

# Compact record: timestamp, tool, best-effort payload, cwd.
# Small enough that SessionEnd can feed the whole log back to `claude -p`.
printf '%s' "$INPUT" | jq -c --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
  {
    ts: $ts,
    tool: (.tool_name // "?"),
    payload: (
      .tool_input.command
      // .tool_input.file_path
      // .tool_input.pattern
      // .tool_input.url
      // .tool_input.description
      // (.tool_input | tostring | .[0:500])
    ),
    cwd: (.cwd // "")
  }' >> "$SESSIONS_DIR/$SESSION_ID.jsonl" 2>/dev/null

exit 0
