# qiskit-contrib-agent

Private. Self-improving OSS contribution agent for Qiskit. Runs nightly via
Codex (gpt-5.5, xhigh reasoning). Backs up every run + learned lessons here.

## Layout

| Path | Purpose |
|------|---------|
| `prompt.md` | The careful-contributor workflow (quality gates, no-spam rules). |
| `run.ps1` | Runner. Open-PR guard → Codex run → self-eval → lessons → git push. |
| `lessons.md` | Accumulated lessons. Prepended to the prompt each run. |
| `runs/<timestamp>/` | Per-run artifacts: prompt used, output, summary, new lessons. |

## How it works

1. **Open-PR guard** — if a PR by `TSS99` is already open anywhere on GitHub,
   the agent is forced into evaluation-only mode (standing ≤1 open PR cap).
2. **Contribution run** — Codex executes `prompt.md` against the local Qiskit
   repo, opening at most one PR, only if every quality gate passes.
3. **Self-improvement** — a second Codex pass extracts concrete lessons from
   the run and appends them to `lessons.md`, so the next run learns.
4. **Backup** — all artifacts are committed and pushed here.

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
