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
      5b. Merged-PR sync (gh)            - refresh merged-prs.md for advocate points.
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
$CapFlagFile  = Join-Path $AgentDir "manual-cap.flag"
$RunsDir      = Join-Path $AgentDir "runs"
$Timestamp    = Get-Date -Format "yyyyMMdd-HHmmss"
$RunDir       = Join-Path $RunsDir $Timestamp

$CodexModel = "gpt-5.5"
$CheapModel = "claude-sonnet-4-6"
$OpusModel  = "claude-opus-4-8"
$MineMaxAgeDays = 7
$MaxOpenPrs     = 3   # ceiling on concurrent open agent-created PRs
$PrCadenceDays  = 1   # target: attempt an agent PR every day (ceiling still caps at $MaxOpenPrs)
$AdvocateNumber = "126759"   # Qiskit Advocate # for the merged-PR points tracker
$ContribGitHub  = "TSS99"    # GitHub handle whose merged Qiskit PRs are tracked

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

# --- PR cadence + concurrency guard ------------------------------------------
# Policy (user-set): land at least one agent PR every $PrCadenceDays days, even
# if earlier ones are still unmerged, up to a ceiling of $MaxOpenPrs concurrently
# open. Legacy pre-existing PRs do not count; only agent PRs in agent-prs.md.
# Stage 1/2 run only when a PR is DUE and we are UNDER the ceiling ($Escalate).
# The correctness floor (reproducer fails on main + tests pass) is enforced in
# the Stage 1 prompt - a week may still be skipped if nothing clears it.
$OpenPrBlock = ""
$Capped    = $false   # at ceiling or unsafe to submit -> skip Stage 1/2
$Escalate  = $false   # PR due and under ceiling       -> push Stage 1 to land one
$WeeklyDue = $false
$OpenCount = 0

# Fail-safe: a prior run that opened a PR but could not parse its URL drops this
# flag so we hold. Clear it manually once you've confirmed PR state.
if (Test-Path $CapFlagFile) {
    $Capped = $true
    $OpenPrBlock = @"
## HARD CONSTRAINT - PR TRACKING HOLD

A prior run reported a submitted PR whose URL could not be parsed, so this hold
is in place. Open no new PR. End with NO SUBMISSION RECOMMENDED, citing the hold.

---

"@
}

if (-not $Capped) {
  try {
    $openUrls = @()
    $lastPrDate = $null
    if (Test-Path $AgentPrsFile) {
        $lines = Get-Content $AgentPrsFile -Encoding UTF8
        foreach ($ln in $lines) {
            $dm = [regex]::Match($ln, "\d{4}-\d{2}-\d{2}")
            if ($dm.Success) {
                $d = [datetime]::ParseExact($dm.Value, "yyyy-MM-dd", $null)
                if (-not $lastPrDate -or $d -gt $lastPrDate) { $lastPrDate = $d }
            }
        }
        $trackedUrls = @(
            $lines | ForEach-Object {
                $m = [regex]::Match($_, "https?://github\.com/[^\s)]+/pull/\d+")
                if ($m.Success) { $m.Value }
            } | Select-Object -Unique
        )
        foreach ($u in $trackedUrls) {
            $st = (gh pr view $u --json state 2>$null | ConvertFrom-Json).state
            # Fail closed: undeterminable state (gh auth/network) counts as open.
            if (-not $st -or $st -eq "OPEN") { $openUrls += $u }
        }
    }
    $OpenCount = $openUrls.Count
    $WeeklyDue = (-not $lastPrDate) -or
                 ((New-TimeSpan -Start $lastPrDate -End (Get-Date)).TotalDays -ge $PrCadenceDays)

    if ($OpenCount -ge $MaxOpenPrs) {
        $Capped = $true
        $list = ($openUrls | ForEach-Object { "- $_" }) -join "`n"
        $OpenPrBlock = @"
## HARD CONSTRAINT - CONCURRENT PR CEILING ($MaxOpenPrs)

$MaxOpenPrs agent PRs are already open:
$list

Do not open another until one merges or closes. End with NO SUBMISSION
RECOMMENDED, citing the concurrency ceiling.

---

"@
    } elseif ($WeeklyDue) {
        $Escalate = $true
        $OpenPrBlock = @"
## WEEKLY TARGET DUE - LAND ONE PR THIS RUN (floor still applies)

It has been at least $PrCadenceDays days since the last agent PR (or there is
none yet), and $OpenCount of $MaxOpenPrs agent PRs are open, so you MAY open one
more. Actively search, pick the single best available candidate, prepare it, and
hand off with DECISION: SUBMIT.

Correctness floor - do NOT breach it to hit the target:
- the reproducer MUST fail on unpatched current main, and
- your added/changed tests MUST pass after the fix.
If after honest effort nothing clears this floor, end with NO SUBMISSION
RECOMMENDED. A missed week is acceptable; a junk PR is not. Bias toward narrow
transpiler/primitives bugs per the merge patterns above.

---

"@
    }
  } catch {
    # Fail closed: a broken cap check must not let an untracked PR through.
    $Capped = $true
    Write-Host "Could not check agent PR status ($_). Failing closed - skipping contribution stages this run." -ForegroundColor Red
  }
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

# --- Build-readiness gate ----------------------------------------------------
# Stage 1/2 need a Qiskit checkout that actually builds and imports. Without the
# Rust _accelerate extension, `import qiskit` fails outright, so every candidate
# is unreproducible and Codex correctly bails with NO SUBMISSION every run. Detect
# that here and say so loudly instead of burning a Codex call to rediscover it.
function Test-BuildReady([string]$Repo) {
    if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) { return $false }
    Push-Location $Repo
    try {
        python -c "import qiskit._accelerate" 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    } finally { Pop-Location }
}

$BuildOk = Test-BuildReady $RepoPath
if (-not $BuildOk) {
    Log "BUILD GATE FAILED: cargo and/or qiskit._accelerate not importable in $RepoPath." "Red"
    Log "Stage 1 + Stage 2 skipped. Fix once with: $AgentDir\setup-build.ps1" "Red"
}

# gh auth gate: mining, Stage 1 issue search, and Stage 2 PR creation all need
# an authenticated gh. If it's dead, skip the expensive stages loudly rather
# than half-run them and produce confusing failures downstream.
gh auth status 2>$null | Out-Null
$GhOk = ($LASTEXITCODE -eq 0)
if (-not $GhOk) {
    Log "GH AUTH FAILED: gh is not authenticated. Stage 1 + Stage 2 skipped. Run: gh auth login" "Red"
}

if (-not ($Escalate -and $BuildOk -and $GhOk)) {
    if (-not $BuildOk)       { Log "Build gate failed - skipping pattern mining, Stage 1 and Stage 2." "Yellow" }
    elseif (-not $GhOk)      { Log "gh auth failed - skipping pattern mining, Stage 1 and Stage 2." "Yellow" }
    elseif ($Capped)         { Log "At concurrency ceiling ($OpenCount/$MaxOpenPrs open) - skipping pattern mining, Stage 1 and Stage 2." "Yellow" }
    elseif (-not $WeeklyDue) { Log "No PR due yet (last agent PR < $PrCadenceDays days ago) - skipping pattern mining, Stage 1 and Stage 2." "Gray" }
    else                     { Log "Skipping pattern mining, Stage 1 and Stage 2." "Yellow" }
} else {
    Log "PR due and under ceiling ($OpenCount/$MaxOpenPrs open) - running contribution stages." "Cyan"

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
        # Stage 1 fast-forwards main to upstream before committing its fix, so the
        # _accelerate binary setup-build.ps1 compiled at an older commit may be
        # stale. Rebuild against the branch state before Opus runs any tests, so
        # validation reflects current source, not an outdated extension.
        Log "Rebuilding qiskit._accelerate before verification..." "Cyan"
        Push-Location $RepoPath
        try { pip install -e . 2>&1 | Out-Null } finally { Pop-Location }
        if ($LASTEXITCODE -ne 0) {
            Log "Rebuild reported a non-zero exit - Opus will run against a possibly stale extension." "DarkYellow"
        }

        Log "Stage 2: Opus ($OpusModel) verifying the prepared change..." "Cyan"
        $verifyTemplate = Get-Content $VerifyFile -Raw -Encoding UTF8
        $verifyPrompt = $verifyTemplate.Replace("{{CODEX_HANDOFF}}", $MainOutput)

        $AllowedTools = @(
            "Bash(git:*)", "Bash(gh:*)",
            "Bash(python:*)", "Bash(python3:*)", "Bash(py:*)",
            "Bash(pytest:*)", "Bash(stestr:*)", "Bash(tox:*)", "Bash(nox:*)",
            "Bash(black:*)", "Bash(ruff:*)", "Bash(pylint:*)", "Bash(mypy:*)",
            "Bash(pip:*)", "Bash(reno:*)", "Bash(cargo:*)", "Bash(maturin:*)",
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
                "PR SUBMITTED on $(Get-Date -Format 'yyyy-MM-dd HH:mm') but URL not parsed - see runs\$Timestamp\opus-verify.txt. Delete this file once PR state is confirmed." |
                    Out-File -FilePath $CapFlagFile -Encoding UTF8
                Log "Stage 2: Opus reported PR SUBMITTED but no URL parsed. Dropped manual-cap.flag to block new PRs. Check opus-verify.txt." "Red"
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

# --- Stage 5b: Merged-PR tracker sync (advocate points) ----------------------
# Keep merged-prs.md in step with reality so the user can claim Qiskit Advocate
# points. Rebuilds the table from gh (the source of truth for merge state) while
# preserving the human-set [x] "claimed" ticks. Runs whenever gh is authenticated,
# independent of the contribution cadence gate - merges can land any time.
$MergedPrsFile = Join-Path $AgentDir "merged-prs.md"
if ($GhOk) {
    Log "Syncing merged-PR tracker (advocate #$AdvocateNumber)..." "Yellow"
    $mergedJson = gh pr list --repo Qiskit/qiskit --author $ContribGitHub --state merged --limit 100 --json number,title,url,mergedAt 2>$null | Out-String
    # PS5.1: ConvertFrom-Json emits a JSON array as one pipeline object, so assign
    # first then re-wrap with @() for a correct element count (see header note).
    try { $parsed = $mergedJson | ConvertFrom-Json; $merged = @($parsed) } catch { $merged = @() }
    if ($merged.Count -gt 0) {
        # Preserve which PR numbers the user already ticked as claimed.
        $claimed = @{}
        if (Test-Path $MergedPrsFile) {
            foreach ($ln in (Get-Content $MergedPrsFile -Encoding UTF8)) {
                $m = [regex]::Match($ln, '^\|\s*\[(x| )\]\s*\|\s*#(\d+)')
                if ($m.Success) { $claimed[[int]$m.Groups[2].Value] = ($m.Groups[1].Value -eq 'x') }
            }
        }
        $rows = $merged | Sort-Object { $_.mergedAt } | ForEach-Object {
            $n = [int]$_.number
            $tick = if ($claimed.ContainsKey($n) -and $claimed[$n]) { 'x' } else { ' ' }
            $title = ($_.title -replace '\|', '\').Trim()
            "| [$tick] | #$n | $($_.mergedAt.Substring(0,10)) | $title | $($_.url) |"
        }
        $today = Get-Date -Format "yyyy-MM-dd"
        $content = @"
# Qiskit Advocate - Merged PR Tracker

**Advocate #:** $AdvocateNumber
**GitHub:** $ContribGitHub
**Repo:** Qiskit/qiskit
**Purpose:** Track merged PRs to claim points in the Qiskit Advocate programme (Airtable form).

How to use: when a PR merges it is added below with the Claimed box unticked [ ]. After you
submit it in the advocate Airtable form, change [ ] to [x] so you know it is already claimed.

| Claimed | PR | Merged | Title | Link |
|:-------:|----|--------|-------|------|
$($rows -join "`n")

_Last updated: ${today}_
"@
        $content | Out-File -FilePath $MergedPrsFile -Encoding UTF8
        Log "Merged-PR tracker synced ($($merged.Count) merged)." "Green"
    } else {
        Log "Merged-PR tracker: gh returned no merged PRs - leaving file unchanged." "DarkYellow"
    }
} else {
    Log "gh auth failed - skipping merged-PR tracker sync." "Yellow"
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
