# Changelog

All notable changes to learnFromClaude.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned
- Share-this-card button (pre-fills a tweet with the card's lesson + repo link)
- Export to Anki / plain Markdown
- Per-tag stats and weekly digest

## [0.1.0] — 2026-04-13

First public release.

### Added
- **Plugin marketplace** at `pathakcodes/learnFromClaude` with auto-registered
  `PostToolUse` and `SessionEnd` hooks
- **Slash commands**: `/learn-from-claude:dashboard`, `/learn-from-claude:settings`
- **Local dashboard** at `http://127.0.0.1:8765/` with:
  - Stacked declarative learning cards (not quiz flashcards)
  - Tag cloud sidebar with click-to-filter
  - Daily timeline (Today / Yesterday / dated buckets) with bar visualization
  - Live fuzzy search across title, lesson, details, tags, code
  - Per-card likes (server-persisted, with global liked-only filter)
  - Session-id badge on every card; click copies `claude --resume <id>` to clipboard
  - In-UI settings modal that round-trips to `CONFIG.md` on disk
  - Per-card delete with confirmation
  - Keyboard shortcuts: `/`, `←`/`→`, `L`, `Shift+L`, `S`, `,`, `Esc`
- **Plain-English `CONFIG.md`** injected verbatim into the summarizer prompt —
  no parsers, no schemas, edit knobs and prose in one file
- **ROOT/DATA_DIR split**: plugin assets live in the plugin cache (safe to wipe
  on update), user state lives in `~/.claude/learnFromClaude/` (durable)
- **Manual installer** (`install.sh`) for users outside the plugin system, with
  idempotent settings.json merging
- **Uninstaller** (`uninstall.sh`) with `--purge` flag for full data removal
- **Atomic disk writes** for `flashcards.json` and `CONFIG.md` (tmp + rename)

### Architecture decisions
- Hooks run detached from session exit (`& disown`) so summarization never
  blocks the user
- Server is single-threaded with explicit `FILE_LOCK` to make concurrent-write
  safety explicit and survive a future swap to `ThreadingTCPServer`
- Dashboard uses safe DOM APIs (`createElement` + `textContent`) — no
  `innerHTML`, eliminating any XSS surface from card content
- Card content shown as a *learning surface*, not a flip-revealed Q&A —
  declarative front, details below, all visible at once

[Unreleased]: https://github.com/pathakcodes/learnFromClaude/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/pathakcodes/learnFromClaude/releases/tag/v0.1.0
