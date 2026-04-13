# Growth playbook — learnFromClaude

> Reference document for promoting and growing this plugin.
> Living doc: revise after every launch attempt with what worked / what didn't.

Stars are a lagging indicator. The thing that actually drives them is *one*
well-timed, well-targeted post — not consistent effort across many channels.
This document is the sequenced playbook for that.

---

## Week 1 — make the surface convince a stranger in 8 seconds

Open the repo in an incognito window and ask: *if I'd never heard of this,
would I install it in 30 seconds?* If not, fix the README before any promotion.

Concrete README fixes (status: ✅ applied):

- [x] **GIF as the first non-text element** — most readers stop at the first
      visual. Hero PNG demoted to a static fallback further down.
- [x] **Elevator line under the tagline** — one sentence anchoring the value
      to the reader's identity, not the product's features.
- [x] **"What you'll see" sub-heading** above install commands so scanners
      know there's a payoff.
- [x] **CHANGELOG.md** linked from README. Signals momentum to anyone who
      lands on a months-old repo.

---

## Week 2 — fire the launch shots in the right order

Order matters. Each platform reaches a different audience and references the
previous launch. Spread these across 5–6 days. Same-day cross-posting reads
as coordinated and demotes everywhere.

### Day 1 — X/Twitter thread

Lead with the GIF. Open with a personal moment, not a feature list:

> Last week I spent 3 hours debugging FluxCD. I forgot the fix by Friday.
>
> So I built learnFromClaude — a Claude Code plugin that turns each session
> into a small stack of learning cards I can revisit.
>
> [GIF]
>
> Install: /plugin marketplace add pathakcodes/learnFromClaude
>
> Card from this morning: "FluxCD retry exhaustion clears only via a
> suspend/resume cycle — annotations like requestedAt and forceAt do not
> reset the failure counter."
>
> https://github.com/pathakcodes/learnFromClaude

End with the repo link. Don't ask for stars, don't tag Anthropic.

### Day 2 — r/ClaudeAI (and r/programming if it goes well there)

Different framing entirely — Reddit downvotes anything that smells coordinated.

> **Title:** Built a plugin that turns my Claude Code sessions into flashcards
>
> **Body:** Sharing in case it's useful. Every session I have ends up
> teaching me 2–3 things I forget within the week. So I wired up two hooks
> (PostToolUse + SessionEnd) and a tiny dashboard. Hooks capture the tool
> log; SessionEnd hands it to a headless `claude -p` with a CONFIG.md I
> can edit; output is 3–5 declarative cards saved locally.
>
> Open source, MIT, runs entirely on your machine.
>
> [GIF]
>
> Repo: https://github.com/pathakcodes/learnFromClaude
>
> Genuinely curious — what kinds of cards do you think would be most
> useful from your own sessions?

### Day 3 — Show HN

> **Title:** Show HN: learnFromClaude – your Claude Code sessions become flashcards
>
> **Body:** Two hooks plus a local dashboard at 127.0.0.1:8765. PostToolUse
> logs every tool call to a per-session JSONL; SessionEnd injects an
> editable CONFIG.md into a headless `claude -p` and gets back 3–5 cards.
> Click any card's session badge → `claude --resume <id>` lands on your
> clipboard.
>
> Why I built it: I keep solving the same problems twice because I forget
> the resolution path between sessions.
>
> Repo: https://github.com/pathakcodes/learnFromClaude

HN crowd hates marketing copy. Be technical, be terse, link the GIF in
a comment after the post catches.

### Day 4 — PRs to awesome-lists

Search GitHub for: `awesome-claude-code`, `awesome-claude`, `awesome-llm-tools`,
`awesome-developer-tools`. Submit one-line PRs adding learnFromClaude.

These are evergreen — they trickle traffic for years.

### Day 5 — Anthropic Discord / Claude Code community channel

Post the GIF and 2 sentences. Don't ask for stars. Ask for *feedback on what
kinds of cards feel weakest* — that's a real question, drives engagement,
and the responses help you ship a v0.2.

### Day 6 — DM 5–10 Claude Code power users individually

Look at who tweets about Claude Code regularly. Personalized message:

> Saw your thread on [X] — built this and thought it might be your kind of
> thing. No need to share, just curious if you'd actually use it.

This converts way better than broadcast. Don't pitch — invite.

---

## Week 3+ — compound the launch into ongoing growth

The launch only converts curious browsers into stargazers. To get *usage*:

### 1. Build a virality loop into the product

Add a **"share this card"** button that opens a tweet composer pre-filled
with the card's title, lesson, and a link to the repo. Every interesting
card a user sees becomes a recruiting moment.

This is the single highest-leverage feature add post-launch.

### 2. Ship one thoughtful update every 2 weeks for a quarter

Each update = a tweet = an excuse to re-share the GIF. Suggested cadence:

- **v0.2** — share-this-card button + tweet template
- **v0.3** — export to Anki / Markdown
- **v0.4** — per-tag stats and weekly digest
- **v0.5** — multi-machine sync (opt-in, encrypted, BYO storage)
- **v0.6** — "weakest topic" digest (tags you've liked few cards from)

Frequency builds trust that this isn't a dead repo.

### 3. Write one technical post per month

Long-tail SEO + reusable content. Topic ideas:

- "Why I made CONFIG.md the prompt"
- "What 100 sessions taught me about prompt-injecting your own config file"
- "The economics of headless `claude -p` in a hook"
- "Splitting plugin assets from user state in Claude Code"
- "Building a virality loop for a learning tool"

Cross-post to the personal blog, dev.to, Hashnode, LinkedIn.

### 4. Get one influential person to use it visibly

One tweet from someone with 10K+ Claude Code-following devs is worth more
than 50 of your own posts.

Strategy: ship a feature *they specifically asked for* in a thread you saw,
then DM them when it's live.

---

## What NOT to do

- **Don't ask for stars in the README.** Reads as desperate, converts worse
  than not asking. The GIF + install command + first card is the actual
  conversion mechanism.
- **Don't link the repo in unrelated subreddits or every Claude tweet.**
  That's how new accounts get banned and how repos get a reputation as
  someone's pet project.
- **Don't add analytics or telemetry.** Privacy is one of the top three
  differentiators here. Don't trade it for vanity metrics.
- **Don't add merch (logo on a t-shirt) before 100 stars.** Premature polish
  signals you care more about identity than product.
- **Don't post everywhere on the same day.** Spread launches; let momentum
  on each platform compound independently.

---

## Honest baselines for expectation-setting

| Outcome | What it usually takes |
|---|---|
| 5–20 stars from a Twitter launch | Tweet thread with GIF, no audience required |
| 50–200 stars from HN front page | Show HN with technical framing, GIF, 4–6 hour window |
| 200–800 stars in 3 months | Consistent posting + feature update every 2 weeks |
| 1000+ stars | Either a name brand boosting you or a viral product loop |

learnFromClaude has ingredients for the latter: every interesting card
a user sees is a shareable moment. Build the share button.

---

## What success actually looks like

Not stars. Stars are vanity. Track these instead:

1. **Plugin marketplace install count** (when Claude Code exposes it)
2. **Issues opened by people other than you** — proves real usage
3. **PRs from contributors** — proves real investment
4. **Weekly active card generations** — if you instrument it later, opt-in
5. **Mentions in posts you didn't write** — search "learnFromClaude" weekly

If those numbers grow, the stars follow. If they don't, more posts won't help.

---

## Post-launch retrospective template

After each major launch attempt, append a section here:

```
### YYYY-MM-DD — [channel]
- What I posted: [link]
- Stars before / after / 24h-after:
- Top comment / question:
- Surprise:
- Next time:
```

This is how the playbook gets sharper — turn each launch into a learning
card for the project itself.
