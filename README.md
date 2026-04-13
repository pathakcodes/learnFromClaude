# learnFromClaude

> Turn every Claude Code session into a stack of learning cards you can revisit.

A Claude Code plugin that passively captures your tool use during a session, asks Claude to extract 3–5 genuinely teachable moments at session end, and surfaces them in a local dashboard with tags, a daily timeline, search, likes, and one-click session resume.

You use Claude Code. Claude Code teaches you back.

---

## What it does

- **Captures** every tool call during a session (Bash, Edit, Grep, etc.) to a per-session JSONL log.
- **Summarizes** at session end by feeding the log + your `CONFIG.md` to a headless `claude -p`. Output is 3–5 declarative learning cards (not quiz questions).
- **Surfaces** cards in a local dashboard at `http://127.0.0.1:8765/` — tags, timeline, search, likes, session-id badge that copies `claude --resume <id>` to your clipboard.

Everything runs locally. Your sessions never leave your machine.

---

## Install (recommended: Claude Code plugin)

Inside a Claude Code session:

```
/plugin marketplace add github:pathakcodes/learnFromClaude
/plugin install learn-from-claude@learnFromClaude
```

That's it. Hooks auto-register. Start a fresh Claude Code session; when it ends, your first cards will appear.

To open the dashboard:

```
/learn-from-claude:dashboard
```

Or run the shipped CLI directly: `python3 ~/.claude/plugins/cache/learnFromClaude/learn-from-claude/*/server.py`

---

## Install (manual — without the plugin system)

```bash
git clone https://github.com/pathakcodes/learnFromClaude.git
cd learnFromClaude
bash install.sh
```

Or one-shot:

```bash
curl -fsSL https://raw.githubusercontent.com/pathakcodes/learnFromClaude/main/install.sh | bash
```

Then run `learnFromClaude` to open the dashboard.

**Prerequisites:** `claude` CLI, `python3`, `jq`.

---

## Using the dashboard

Open it (`/learn-from-claude:dashboard` or the `learnFromClaude` CLI), then:

| Action | Shortcut |
|---|---|
| Search | `/` |
| Next / prev card | `→` / `←` |
| Like current card | `L` |
| Show only liked | `Shift+L` |
| Shuffle | `S` |
| Open settings | `,` |
| Clear filters / close modal | `Esc` |

**Session resume:** click the session badge on any card. `claude --resume <id>` lands on your clipboard. Paste into any terminal to jump back to the exact Claude Code session that generated the card.

---

## Configuration

Extraction behavior is controlled by a single file: `~/.claude/learnFromClaude/CONFIG.md`.

It's read verbatim into the summarizer's prompt, so you edit it in plain English:

```markdown
## Defaults
- **cards_per_session**: 3 to 5
- **min_session_events**: 3
- **max_session_events**: 300

## What to extract
1. Non-obvious CLI invocations…
2. Root-cause debugging patterns…

## What to skip
- Trivial shell: `ls`, `cd`, `pwd`, `echo`, `cat`, `which`, `clear`
- Routine file reads with no insight attached
…
```

Edit it from the dashboard (press `,` or click the gear icon) or directly in your editor. Changes take effect at the next session end — no restart needed.

---

## How it works

```
┌──────────────────────┐   PostToolUse    ┌──────────────────────┐
│  Claude Code session │ ───────────────▶ │  capture.sh          │
│  (Bash, Edit, Grep…) │                  │  → sessions/<id>.jsonl│
└──────────┬───────────┘                  └──────────────────────┘
           │ SessionEnd
           ▼
┌──────────────────────┐  headless       ┌──────────────────────┐
│  summarize.sh        │ ──── claude -p ▶│  CONFIG.md + log →    │
│  (detached)          │                 │  JSON learning cards  │
└──────────┬───────────┘                 └──────────┬───────────┘
           │                                         │
           │  append (atomic tmp + rename)           │
           ▼                                         ▼
       flashcards.json ◀──── dashboard.html ◀── localhost:8765
                              server.py
```

- **Plugin dir** (`~/.claude/plugins/cache/.../learn-from-claude/<version>/`) — code, static assets, default `CONFIG.md`. Safe to wipe; plugin updates replace it.
- **Data dir** (`~/.claude/learnFromClaude/`) — your cards, session logs, edited `CONFIG.md`. Survives plugin updates.

The summarizer is *detached* (`&` + `disown`) so session exit is instant. It writes to `summarize.log` if anything goes wrong.

---

## Uninstall

Plugin install:

```
/plugin uninstall learn-from-claude@learnFromClaude
/plugin marketplace remove learnFromClaude
```

Manual install:

```bash
bash ~/projects/learnFromClaude/uninstall.sh          # keeps your cards
bash ~/projects/learnFromClaude/uninstall.sh --purge  # also deletes data dir
```

---

## Privacy

Everything runs on your machine. The only network calls are:
1. `claude -p` — subject to the same privacy terms as your regular Claude Code use.
2. Your browser hitting `127.0.0.1:8765` — never leaves localhost.

No telemetry. No cloud sync. The cards file is a plain JSON — yours to grep, edit, version, or delete.

---

## Contributing

Issues and PRs welcome. If the summarizer is producing weak cards, the fix is usually in `CONFIG.md` — start there before patching code.

---

## License

MIT — see [LICENSE](LICENSE).

Made with ♥ by [@pathakcodes](https://github.com/pathakcodes).
