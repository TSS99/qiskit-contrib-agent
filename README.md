# qiskit-contrib-agent

Private. Self-improving OSS contribution agent for Qiskit. Runs nightly via
Codex (gpt-5.5, xhigh reasoning). Backs up every run + learned lessons here.

## Layout

| Path | Purpose |
|------|---------|
| `prompt.md` | Stage 1 workflow (Codex): careful contributor, quality gates, prepare-only. |
| `verify-prompt.md` | Stage 2 workflow (Opus 4.8): verify, fix, push, open PR. |
| `run.ps1` | Runner. Guard → Codex prepare → Opus verify+submit → self-eval → push. |
| `lessons.md` | Accumulated lessons. Prepended to the prompt each run. |
| `runs/<timestamp>/` | Per-run artifacts: prompt used, summary, opus-verify, new lessons. |

## How it works

1. **Open-PR guard** — if a PR by `TSS99` is already open anywhere on GitHub,
   the agent is forced into evaluation-only mode (standing ≤1 open PR cap).
2. **Stage 1 — Codex prepares** — Codex (gpt-5.5, xhigh) executes `prompt.md`
   against the local Qiskit repo. It makes one local commit on a branch but
   does NOT push or open a PR; it hands off a structured report.
3. **Stage 2 — Opus verifies + submits** — if Stage 1 prepared a change, Opus
   4.8 independently verifies correctness, fixes what it must, re-runs tests,
   and only then pushes to the fork and opens the PR. If unfixable, it blocks.
4. **Self-improvement** — a Codex pass extracts concrete lessons from both
   stages and appends them to `lessons.md`, so the next run learns.
5. **Backup** — all artifacts are committed and pushed here.

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
