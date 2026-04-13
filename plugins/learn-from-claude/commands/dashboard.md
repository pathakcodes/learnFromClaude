---
description: Open the learnFromClaude dashboard in your browser
---

Start the learnFromClaude dashboard server and open it in the default browser.

Run this command in the background (use Bash with run_in_background: true):

```
python3 "${CLAUDE_PLUGIN_ROOT}/server.py"
```

The server prints the URL (default: http://127.0.0.1:8765/) and auto-opens the browser. If port 8765 is taken, set `LEARN_FROM_CLAUDE_PORT` to a free port, e.g.:

```
LEARN_FROM_CLAUDE_PORT=8890 python3 "${CLAUDE_PLUGIN_ROOT}/server.py"
```

After launching, tell the user the dashboard is up and remind them of the keyboard shortcuts: `/` search · `←`/`→` nav · `L` like · `S` shuffle · `,` settings.
