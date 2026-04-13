---
description: Edit learnFromClaude's extraction config (CONFIG.md)
---

Open the user's learnFromClaude CONFIG.md so they can tweak what cards get extracted and how many.

1. If the dashboard is already running, the easiest path is pressing `,` in the UI — it opens the settings modal. Tell the user that first.
2. Otherwise, open `~/.claude/learnFromClaude/CONFIG.md` in their editor with the Read tool so they can review the current values (cards_per_session, min/max session events, extraction categories, skip rules, card style, custom instructions).
3. If they want to edit specific knobs, make the targeted changes with Edit. The summarizer picks up changes at the next session end — no restart needed.
