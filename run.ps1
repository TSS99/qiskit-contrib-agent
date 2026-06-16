<#
.SYNOPSIS
    Qiskit contribution agent - two-stage, feedback-driven, self-improving.

.DESCRIPTION
    Pipeline per run:
      0. Feedback ingest (sonnet + gh)  - learn from real maintainer reactions.
      -  Open-PR cap guard               - if >=1 open PR, skip the expensive
                                           contribution stages entirely.
      1. Pattern mining (sonnet + gh)    - refresh merged-patterns.md weekly.
      2. Stage 1 Codex prepare (xhigh)   - local branch + commit only.
      3. Stage 2 Opus verify + submit    - independent check, then push + PR.
      4. Ledger update (sonnet)          - record evaluated issues to skip later.
      5. Lesson curator (sonnet)         - merge + dedup + cap lessons.md.
      6. Backup push                     - commit artifacts to private repo.

.PARAMETER RepoPath
    Path to the local Qiskit git clone. Must be a real git checkout (the parent
    Qiskit_Advocate folder is NOT one). Defaults to the qiskit fork clone.

.PARAMETER DryRun
    Print the assembled Stage 1 prompt and exit. No model calls, no pushes.
#>
param(
    [string]$RepoPath = "D:\CDAC Projects\Qiskit_Advocate\qiskit",
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AgentDir     = $PSScriptRoot
$PromptFile   = Join-Path $AgentDir "prompt.md"
$VerifyFile   = Join-Path $AgentDir "verify-prompt.md"
$FeedbackFile = Join-Path $AgentDir "feedback-prompt.md"
$MineFile     = Join-Path $AgentDir "mine-prompt.md"
$LessonsFile  = Join-Path $AgentDir "lessons.md"
$PatternsFile = Join-Path $AgentDir "merged-patterns.md"
$LedgerFile   = Join-Path $AgentDir "evaluated-issues.md"
$AgentPrsFile = Join-Path $AgentDir "agent-prs.md"
$RunsDir      = Join-Path $AgentDir "runs"
$Timestamp    = Get-Date -Format "yyyyMMdd-HHmmss"
$RunDir       = Join-Path $RunsDir $Timestamp

$CodexModel = "gpt-5.5"
$CheapModel = "claude-sonnet-4-6"
$OpusModel  = "claude-opus-4-8"
$MineMaxAgeDays = 7

# --- Validate ----------------------------------------------------------------

if (-not (Test-Path $PromptFile)) { Write-Error "prompt.md not found at $PromptFile"; exit 1 }
if (-not (Test-Path $RepoPath))   { Write-Error "Repo path does not exist: $RepoPath"; exit 1 }
if (-not (Test-Path (Join-Path $RepoPath ".git"))) {
    Write-Error "RepoPath is not a git checkout: $RepoPath (point it at the clone, e.g. ...\Qiskit_Advocate\qiskit)"
    exit 1
}

function Get-FileOrDefault([string]$Path, [string]$Default) {
    if (Test-Path $Path) {
        $c = (Get-Content $Path -Raw -Encoding UTF8).Trim()
        if ($c) { return $c }
    }
    return $Default
}

# --- Assemble Stage 1 prompt -------------------------------------------------

function Build-Stage1Prompt([string]$OpenPrBlock) {
    $base     = Get-Content $PromptFile -Raw -Encoding UTF8
    $patterns = Get-FileOrDefault $PatternsFile "(no mined patterns yet)"
    $lessons  = Get-FileOrDefault $LessonsFile  ""
    $ledger   = Get-FileOrDefault $LedgerFile   ""

    $patternsBlock = @"
## WHAT ACTUALLY GETS MERGED - FOLLOW THIS

Grounded in real merged/closed PRs. This is the proven pattern; do not run blind
trial-and-error against maintainers. Bias issue selection toward what merges.

$patterns

---

"@

    $lessonsBlock = ""
    if ($lessons) {
        $lessonsBlock = @"
## LEARNED LESSONS - APPLY BEFORE ANYTHING ELSE

$lessons

---

"@
    }

    $ledgerBlock = ""
    if ($ledger) {
        $ledgerBlock = @"
## ALREADY-EVALUATED ISSUES - DO NOT RE-EVALUATE REJECTED ONES

$ledger

---

"@
    }

    return $OpenPrBlock + $patternsBlock + $lessonsBlock + $ledgerBlock + $base
}

# --- One-at-a-time cap guard -------------------------------------------------
# Policy: pre-existing PRs (the legacy 5) are left alone and do NOT count. The
# agent only counts PRs IT opened (tracked in agent-prs.md). If any of those is
# still open, do not open another - one agent PR at a time. This honors the
# anti-volume feedback (jakelishman batch-closed 8 PRs) without blocking on old
# work the user has chosen to leave as-is.
$OpenPrBlock = ""
$Capped = $false
try {
    if (Test-Path $AgentPrsFile) {
        $trackedUrls = @(
            Get-Content $AgentPrsFile -Encoding UTF8 |
            ForEach-Object {
                $m = [regex]::Match($_, "https?://github\.com/[^\s)]+/pull/\d+")
                if ($m.Success) { $m.Value }
            } | Select-Object -Unique
        )
        $stillOpen = @()
        foreach ($u in $trackedUrls) {
            $st = (gh pr view $u --json state 2>$null | ConvertFrom-Json).state
            if ($st -eq "OPEN") { $stillOpen += $u }
        }
        if ($stillOpen.Count -ge 1) {
            $Capped = $true
            $list = ($stillOpen | ForEach-Object { "- $_" }) -join "`n"
            $OpenPrBlock = @"
## HARD CONSTRAINT - ONE-AT-A-TIME CAP

The agent already has an open PR it created:
$list

Open at most ONE agent-created PR at a time. Do not open another until that one
merges or closes. End with NO SUBMISSION RECOMMENDED, citing the one-at-a-time cap.

---

"@
        }
    }
} catch {
    Write-Host "Warning: could not check agent PR status ($_). Proceeding without guard." -ForegroundColor DarkYellow
}

# --- Dry run -----------------------------------------------------------------

if ($DryRun) {
    Write-Host "=== DRY RUN: Stage 1 prompt (capped=$Capped) ===" -ForegroundColor Cyan
    Write-Host (Build-Stage1Prompt $OpenPrBlock)
    exit 0
}

# --- Setup -------------------------------------------------------------------

New-Item -ItemType Directory -Force -Path $RunDir | Out-Null

# From here on we drive native exes (codex, claude, git, gh). In PS 5.1 a native
# command writing to stderr becomes a fatal NativeCommandError under "Stop" even
# on exit code 0 (e.g. `git push` prints progress to stderr). We gate on
# $LASTEXITCODE explicitly, so downgrade to Continue to avoid false failures.
$ErrorActionPreference = "Continue"

function Log([string]$Msg, [string]$Color = "White") {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Msg" -ForegroundColor $Color
}

# Run claude headless, capture stdout. $Tools = "" means no tools needed.
function Invoke-Claude {
    param([string]$Prompt, [string]$Model, [string]$Tools = "", [string]$WorkDir = $AgentDir)
    Push-Location $WorkDir
    try {
        if ($Tools) {
            return $Prompt | claude -p --model $Model --permission-mode default --allowedTools $Tools --add-dir $WorkDir 2>&1 | Out-String
        } else {
            return $Prompt | claude -p --model $Model --permission-mode default 2>&1 | Out-String
        }
    } finally {
        Pop-Location
    }
}

$ExistingLessons = Get-FileOrDefault $LessonsFile "(none yet)"

# --- Stage 0: Feedback ingest (always) ---------------------------------------

Log "Stage 0: ingesting real maintainer feedback..." "Cyan"
$FeedbackLessons = ""
if (Test-Path $FeedbackFile) {
    $fbTemplate = Get-Content $FeedbackFile -Raw -Encoding UTF8
    $fbPrompt = $fbTemplate.Replace("{{EXISTING_LESSONS}}", $ExistingLessons)
    $FeedbackOut = Invoke-Claude -Prompt $fbPrompt -Model $CheapModel -Tools "Bash(gh:*)"
    $FeedbackOut | Out-File -FilePath (Join-Path $RunDir "feedback.md") -Encoding UTF8
    if ($FeedbackOut -match "NO NEW FEEDBACK") {
        Log "No new maintainer feedback." "Gray"
    } else {
        $FeedbackLessons = $FeedbackOut.Trim()
        Log "Feedback lessons captured." "Green"
    }
} else {
    Log "feedback-prompt.md missing - skipping feedback ingest." "DarkYellow"
}

$MainOutput = ""
$OpusOutput = ""

if ($Capped) {
    Log "Open-PR cap reached - skipping pattern mining, Stage 1 and Stage 2." "Yellow"
} else {

    # --- Stage 1.5: Pattern mining (weekly) ----------------------------------

    $needsMining = $true
    if (Test-Path $PatternsFile) {
        $ageDays = (New-TimeSpan -Start (Get-Item $PatternsFile).LastWriteTime -End (Get-Date)).TotalDays
        if ($ageDays -lt $MineMaxAgeDays) { $needsMining = $false }
    }
    if ($needsMining -and (Test-Path $MineFile)) {
        Log "Pattern mining: refreshing merged-patterns.md from upstream..." "Cyan"
        $currentPatterns = Get-FileOrDefault $PatternsFile "(none yet)"
        $mineTemplate = Get-Content $MineFile -Raw -Encoding UTF8
        $minePrompt = $mineTemplate.Replace("{{CURRENT_PATTERNS}}", $currentPatterns)
        $MineOut = Invoke-Claude -Prompt $minePrompt -Model $CheapModel -Tools "Bash(gh:*) Read Write Edit"
        $MineOut | Out-File -FilePath (Join-Path $RunDir "mining.md") -Encoding UTF8
        Log "Pattern mining done." "Green"
    } else {
        Log "Patterns fresh (< $MineMaxAgeDays days) - skipping mining." "Gray"
    }

    # --- Stage 1: Codex prepare ----------------------------------------------

    $Stage1Prompt = Build-Stage1Prompt $OpenPrBlock
    $Stage1Prompt | Out-File -FilePath (Join-Path $RunDir "prompt-used.md") -Encoding UTF8

    Log "Stage 1: Codex ($CodexModel, xhigh) preparing contribution..." "Cyan"
    Log "Repo: $RepoPath" "Gray"
    $MainOutputFile = Join-Path $RunDir "output.txt"

    # danger-full-access (not workspace-write): on Windows the sandboxed token
    # can't acquire schannel TLS credentials, so `git fetch` fails even with
    # network enabled. Full access matches the user's global codex config
    # (approval=never, trusted project) and Stage 1 only prepares a local commit
    # - push/PR are gated to Stage 2 Opus, which runs with a scoped allowlist.
    $Stage1Prompt | codex exec `
        -m $CodexModel `
        -c "model_reasoning_effort=`"xhigh`"" `
        -s danger-full-access `
        -C $RepoPath `
        -o $MainOutputFile

    $MainExit = $LASTEXITCODE
    if ($MainExit -eq 0) { Log "Stage 1 exited: 0" "Green" } else { Log "Stage 1 exited: $MainExit" "Red" }

    if (Test-Path $MainOutputFile) {
        $MainOutput = Get-Content $MainOutputFile -Raw -Encoding UTF8
    } else {
        $MainOutput = "(no output captured)"
    }
    $MainOutput | Out-File -FilePath (Join-Path $RunDir "summary.md") -Encoding UTF8

    # --- Stage 2: Opus verify + submit ---------------------------------------

    $Stage1Submits = ($MainExit -eq 0) -and ($MainOutput -notmatch "NO SUBMISSION RECOMMENDED")

    if (-not $Stage1Submits) {
        Log "Stage 1 produced no submittable change - skipping Opus verification." "Gray"
    } elseif (-not (Test-Path $VerifyFile)) {
        Log "verify-prompt.md missing - skipping Opus verification." "Red"
    } else {
        Log "Stage 2: Opus ($OpusModel) verifying the prepared change..." "Cyan"
        $verifyTemplate = Get-Content $VerifyFile -Raw -Encoding UTF8
        $verifyPrompt = $verifyTemplate.Replace("{{CODEX_HANDOFF}}", $MainOutput)

        $AllowedTools = @(
            "Bash(git:*)", "Bash(gh:*)",
            "Bash(python:*)", "Bash(python3:*)", "Bash(py:*)",
            "Bash(pytest:*)", "Bash(stestr:*)", "Bash(tox:*)", "Bash(nox:*)",
            "Bash(black:*)", "Bash(ruff:*)", "Bash(pylint:*)", "Bash(mypy:*)",
            "Bash(pip:*)", "Bash(reno:*)",
            "Read", "Edit", "Write", "Grep", "Glob"
        ) -join " "

        Push-Location $RepoPath
        try {
            $OpusOutput = $verifyPrompt | claude -p `
                --model $OpusModel `
                --permission-mode default `
                --allowedTools $AllowedTools `
                --add-dir $RepoPath 2>&1 | Out-String
        } finally {
            Pop-Location
        }
        $OpusOutput | Out-File -FilePath (Join-Path $RunDir "opus-verify.txt") -Encoding UTF8

        if ($OpusOutput -match "PR SUBMITTED") {
            $prUrl = ([regex]::Match($OpusOutput, "https?://github\.com/[^\s)]+/pull/\d+")).Value
            if ($prUrl) {
                $today = Get-Date -Format "yyyy-MM-dd"
                if (-not (Test-Path $AgentPrsFile)) {
                    "# Agent-created PRs (one-at-a-time cap counts these)`n" | Out-File -FilePath $AgentPrsFile -Encoding UTF8
                }
                "- $today | $prUrl" | Out-File -FilePath $AgentPrsFile -Append -Encoding UTF8
                Log "Stage 2: Opus submitted the PR. Tracked: $prUrl" "Green"
            } else {
                Log "Stage 2: Opus reported PR SUBMITTED but no URL parsed - one-at-a-time cap may not engage. Check opus-verify.txt." "Red"
            }
        } elseif ($OpusOutput -match "NO SUBMISSION RECOMMENDED") {
            Log "Stage 2: Opus blocked submission." "Yellow"
        } else {
            Log "Stage 2: Opus output unclear - review opus-verify.txt." "DarkYellow"
        }
    }

    # --- Stage 4: Ledger update ----------------------------------------------

    if ($MainOutput -and $MainOutput -ne "(no output captured)") {
        Log "Recording evaluated issues to ledger..." "Yellow"
        $ledgerPrompt = @"
From the contribution transcript below, list every GitHub issue that was
evaluated as a candidate, one per line, in this exact format:

<issue-url> | <reject|prepared> | <=10-word reason

Only output those lines. No headers, no commentary. If no issues were evaluated,
output exactly: NONE

Transcript:
---
$MainOutput
---
"@
        $ledgerOut = (Invoke-Claude -Prompt $ledgerPrompt -Model $CheapModel).Trim()
        if ($ledgerOut -and $ledgerOut -ne "NONE") {
            $today = Get-Date -Format "yyyy-MM-dd"
            if (-not (Test-Path $LedgerFile)) {
                "# Evaluated issues (skip re-evaluating rejected ones)`n" | Out-File -FilePath $LedgerFile -Encoding UTF8
            }
            ($ledgerOut -split "`n" | ForEach-Object { "- $today | $($_.Trim())" }) -join "`n" |
                Out-File -FilePath $LedgerFile -Append -Encoding UTF8
            "" | Out-File -FilePath $LedgerFile -Append -Encoding UTF8
            Log "Ledger updated." "Green"
        }
    }
}

# --- Stage 5: Lesson curator (always) ----------------------------------------

Log "Curating lessons (merge + dedup + cap)..." "Yellow"
$transcriptForCurate = ""
if ($MainOutput) { $transcriptForCurate += "=== STAGE 1 (CODEX) ===`n$MainOutput`n`n" }
if ($OpusOutput)  { $transcriptForCurate += "=== STAGE 2 (OPUS) ===`n$OpusOutput`n`n" }
if (-not $transcriptForCurate) { $transcriptForCurate = "(no contribution run this cycle - capped)" }

$curatePrompt = @"
You curate the lessons file for a Qiskit contribution agent. Produce a clean,
deduplicated, prioritized lessons list. Output ONLY the new file contents.

Rules:
- Keep at most 30 lessons total. If over, merge near-duplicates and drop the
  weakest/most generic.
- Each lesson is one line: `- [TAG]: <imperative lesson>` where TAG is one of
  FEEDBACK (real maintainer signal - highest priority, never drop these),
  SELECTION (issue picking), TECHNICAL (the fix/tests), PRSTYLE (PR body/branch).
- Incorporate the new feedback lessons and any lessons implied by this run.
- Be specific and actionable. No generic filler. No commentary, no headers other
  than the lines themselves.

CURRENT LESSONS:
$ExistingLessons

NEW FEEDBACK LESSONS (highest priority - integrate, tag FEEDBACK):
$FeedbackLessons

THIS RUN's TRANSCRIPT (extract any concrete lesson):
---
$transcriptForCurate
---
"@

$Curated = (Invoke-Claude -Prompt $curatePrompt -Model $CheapModel).Trim()
if ($Curated -and $Curated.Length -gt 10) {
    $Curated | Out-File -FilePath $LessonsFile -Encoding UTF8
    Log "lessons.md rewritten (curated)." "Green"
} else {
    Log "Curator returned nothing usable - leaving lessons.md unchanged." "DarkYellow"
}

# --- Stage 6: Backup push ----------------------------------------------------

Log "Committing run artifacts to backup repo..." "Yellow"
git -C $AgentDir add -A 2>&1 | Out-Null
$CommitMsg = "Run $Timestamp (capped=$Capped)"
git -C $AgentDir -c user.name="TSS99" -c user.email="tilock.2025@gmail.com" commit -m $CommitMsg 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    git -C $AgentDir push 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Log "Pushed to backup repo." "Green" }
    else { Log "Push failed - artifacts committed locally only." "Red" }
} else {
    Log "Nothing new to commit." "Gray"
}

Log "Done. Artifacts: $RunDir" "Cyan"
