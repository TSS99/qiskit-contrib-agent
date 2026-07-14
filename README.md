# qiskit-contrib-agent

Private. Self-improving OSS contribution agent for Qiskit. Runs nightly via
Codex (gpt-5.5, xhigh reasoning). Backs up every run + learned lessons here.

## Layout

| Path | Purpose |
|------|---------|
| `prompt.md` | Stage 1 workflow (Codex): careful contributor, quality gates, prepare-only. |
| `verify-prompt.md` | Stage 2 workflow (Opus 4.8): verify, fix, push, open PR. |
| `feedback-prompt.md` | Stage 0 (Sonnet): mine real maintainer reactions to TSS99 PRs. |
| `mine-prompt.md` | Pattern-mining (Sonnet): refresh `merged-patterns.md` from upstream. |
| `merged-patterns.md` | What actually gets merged, grounded in real PRs. Injected into Stage 1. |
| `lessons.md` | Curated, tagged, capped lessons. Injected into Stage 1. |
| `evaluated-issues.md` | Ledger of issues already evaluated, to skip re-work. |
| `run.ps1` | Orchestrator for all stages below. |
| `runs/<timestamp>/` | Per-run artifacts: feedback, mining, prompt-used, summary, opus-verify. |

## How it works (per run)

0. **Feedback ingest** (Sonnet + gh) — reads TSS99's merged/closed/open PRs and
   the maintainer comments on them, turning real reactions into `[FEEDBACK]`
   lessons. This is the primary, fastest learning signal.
1. **PR cadence + concurrency guard** — targets **≥1 agent PR every 7 days**,
   even while earlier ones are unmerged, up to a ceiling of **3 concurrently open**
   agent PRs (tracked in `agent-prs.md`; legacy PRs don't count). The expensive
   stages (mining, Stage 1, Stage 2) run only when a PR is *due* and we are *under
   the ceiling*; otherwise only feedback + curation + backup run. The correctness
   floor still applies — a week is skipped rather than ship a PR that can't
   reproduce its bug on main with passing tests.
2. **Pattern mining** (Sonnet + gh, weekly) — studies recently merged upstream
   PRs and rewrites `merged-patterns.md` so issue selection follows what works.
3. **Stage 1 — Codex prepares** (gpt-5.5, xhigh) — screens a broad pool of
   candidates (8-10+ issues across 3+ subsystems), scores each on a 4-axis
   quality rubric (Impact / Merge-confidence / Risk / Rigor-readiness, see
   `prompt.md`), and picks the highest-scoring candidate that clears the
   threshold — favoring real-world impact over merely-safe trivia. Guided by
   the patterns + lessons + ledger. Makes one local commit on a branch, does
   NOT push or open a PR; hands off a structured report including the score.
4. **Stage 2 — Opus verifies + submits** (Opus 4.8, scoped tools) — independently
   verifies correctness, fixes what it must, re-runs tests, then pushes to the
   fork and opens the PR. Blocks if unfixable.
5. **Ledger update** (Sonnet) — records which issues were evaluated, their
   verdict and quality score, so future runs skip known rejects.
6. **Lesson curator** (Sonnet) — merges feedback + run lessons into `lessons.md`,
   deduped, tagged (FEEDBACK/SELECTION/TECHNICAL/PRSTYLE), capped at 30.
7. **Backup** — all artifacts committed and pushed here.

Models: Sonnet for the cheap analytical stages (0, 2, 5, 6), Codex gpt-5.5 xhigh
for preparation (3), Opus 4.8 for verification + submission (4).

## Run manually

```powershell
& "$env:USERPROFILE\.claude\agents\qiskit-contrib\run.ps1"
# preview assembled prompt without running:
& "$env:USERPROFILE\.claude\agents\qiskit-contrib\run.ps1" -DryRun
```

## Schedule

Windows Task Scheduler task `QiskitContribAgent`, daily at 22:00.

```powershell
schtasks /Query /TN QiskitContribAgent /V /FO LIST   # inspect
schtasks /Run   /TN QiskitContribAgent               # run now
schtasks /End   /TN QiskitContribAgent               # stop a run
```
