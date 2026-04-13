# learnFromClaude — Extraction Config

This file tells the session-end summarizer WHAT to extract from your Claude Code
sessions and HOW MUCH. It is read verbatim into the summarizer's prompt, so you
can edit it in plain English and changes take effect on the next session that
ends.

**Editing rules:**
- Keep the section headings as they are — the summarizer uses them to orient.
- The "Defaults" section sets numeric knobs. Tweak the numbers, not the labels.
- Anything you add under "Custom instructions" is appended to the prompt.
- Delete sections you do not want; the summarizer falls back to its baseline.

---

## Defaults

- **cards_per_session**: 3 to 5
- **min_session_events**: 3        (skip sessions smaller than this)
- **max_session_events**: 300      (cap the log the LLM reads)
- **prefer_diversity**: true       (do not cluster all cards on one tool)
- **language**: English

---

## What to extract (priority order)

Generate cards ONLY when the session contains something genuinely teachable.
The bar: would a smart engineer revisit this card in six months and learn
something? If no, skip.

1. **Non-obvious CLI invocations** — commands with unusual flags, pipelines,
   sub-shells, or chained tools that produced a concrete result.
   _Examples worth carding: `kubectl patch ... --type=merge -p '{...}'`,
   `jq --argjson`, `git worktree add`, `lsof -ti:PORT | xargs kill`._

2. **Root-cause debugging patterns** — the sequence of steps that isolated a
   real failure (symptom → hypothesis → evidence → fix). Capture the *method*,
   not just the fix.
   _Example: "FluxCD stuck → tried requestedAt (fail) → forceAt (fail) →
   suspend/resume cycle reset counter"._

3. **Domain knowledge discovered** — how a system in this codebase actually
   works, learned by reading or experimenting. Prefer the underlying mechanism
   to the surface symptom.
   _Example: Rails credentials loaded from `credentials.yml.enc` via
   `master.key`; ephemeral pods bypass `entrypoint.sh` that generates it._

4. **Tool combinations** — useful pairings of Claude Code tools or external
   CLIs that the user may not have used before (Grep multiline + -A/-B,
   `gh pr comment` in a loop, etc.).

5. **Anti-patterns caught** — things that looked right but were wrong, and why.
   Reversal of a common assumption is high-signal.

---

## What to skip

Do NOT create cards for:

- Trivial shell: `ls`, `cd`, `pwd`, `echo`, `cat`, `which`, `clear`.
- Routine file reads with no insight attached.
- One-line edits to rename a variable or fix a typo.
- Git operations that everyone already knows: `git status`, `git add`, plain
  `git commit`, `git push` without unusual flags.
- Session bookkeeping (reading your own memory files, writing logs).
- Boilerplate a user already wrote dozens of times.
- Anything you would describe as "the user just got on with their work."

If the whole session is routine work, return an empty array `[]`. Returning
zero cards is the correct answer when nothing was learned.

---

## Card style — LEARNING CARDS, not quiz flashcards

Cards are DECLARATIVE knowledge surfaces, not Q&A drills. Read like a
Readwise-style highlight or a Kindle clipping: skim-first, details-below.

Required fields:

- **title** — ≤ 60 chars. The *name of the concept*, not a question. Start
  with a verb, noun phrase, or pattern name. Never start with "How to",
  "What is", "Why does", "Understanding". Good: _"Suspend/resume resets
  FluxCD retry counter"_. Bad: _"How do I reset FluxCD retries?"_

- **front** — the LESSON HEADLINE. ≤ 140 chars. A single declarative sentence
  that states the takeaway. No question marks. If you remove the rest of the
  card, this line alone should teach something. Good: _"FluxCD's retry
  counter clears only via a suspend/resume cycle — annotations like
  requestedAt and forceAt do not reset it."_ Bad: _"What clears FluxCD's
  retry counter?"_

- **back** — the DETAILS. 1–4 sentences. Explain the mechanism, the WHY, or
  when to reach for it. Assume the reader already read `front` and doesn't
  need repetition. ≤ 400 chars excluding code.

- **tags** — 2–5 lowercase, single-token tags. Prefer broad ecosystems
  (`kubectl`, `rails`, `bash`, `git`) plus one capability tag (`debugging`,
  `performance`, `workflow`, `security`). Never invent snowflake tags.

- **example** (encouraged) — the actual command, snippet, or minimal
  reproducer from the session. Preserve quoting precisely.

**Tone:** terse, engineer-to-engineer. Declarative. No "you can", no "it's
important to", no questions, no emojis. State the fact.

---

## Output contract

Return ONLY a JSON array, no prose, no markdown fencing. If nothing qualifies,
return `[]`. Never wrap output in ```json.

Schema per element:

```
{
  "title":   "string (≤60 chars)",
  "front":   "string (≤140 chars)",
  "back":    "string (≤300 chars + optional code)",
  "tags":    ["string", "string"],
  "example": "string or omit"
}
```

---

## Custom instructions

Add your own rules here. Examples of things you might add:

- "Prioritize cards about BrowserStack-specific tooling over generic tips."
- "Do not produce cards about Ruby syntax — I already know it."
- "When you see `kubectl` + a failure, always card the recovery path."
- "Prefer cards about the WHY of a system over the WHAT."

(Delete these examples and write your own.)
