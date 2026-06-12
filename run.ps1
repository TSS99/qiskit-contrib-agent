<#
.SYNOPSIS
    Qiskit contribution agent - gpt-5.5 xhigh reasoning, self-improving.

.DESCRIPTION
    Runs the contribution workflow via Codex (gpt-5.5, xhigh reasoning).
    After each run, a second Codex call extracts lessons and appends them
    to lessons.md. The next run prepends those lessons to the prompt so
    the agent learns from past mistakes. Artifacts are pushed to a private
    GitHub backup repo.

.PARAMETER RepoPath
    Path to local Qiskit repo. Defaults to D:\CDAC Projects\Qiskit_Advocate.

.PARAMETER DryRun
    Print the full assembled prompt without running anything.

.EXAMPLE
    .\run.ps1
    .\run.ps1 -RepoPath "D:\CDAC Projects\some-other-repo"
    .\run.ps1 -DryRun
#>
param(
    [string]$RepoPath = "D:\CDAC Projects\Qiskit_Advocate",
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AgentDir    = $PSScriptRoot
$PromptFile  = Join-Path $AgentDir "prompt.md"
$LessonsFile = Join-Path $AgentDir "lessons.md"
$RunsDir     = Join-Path $AgentDir "runs"
$Timestamp   = Get-Date -Format "yyyyMMdd-HHmmss"
$RunDir      = Join-Path $RunsDir $Timestamp

# --- Validate ----------------------------------------------------------------

if (-not (Test-Path $PromptFile)) {
    Write-Error "prompt.md not found at $PromptFile"
    exit 1
}
if (-not (Test-Path $RepoPath)) {
    Write-Error "Repo path does not exist: $RepoPath"
    exit 1
}

# --- Assemble prompt ---------------------------------------------------------

$BasePrompt = Get-Content $PromptFile -Raw -Encoding UTF8

$LessonsBlock = ""
if (Test-Path $LessonsFile) {
    $LessonsContent = (Get-Content $LessonsFile -Raw -Encoding UTF8).Trim()
    if ($LessonsContent) {
        $LessonsBlock = @"
## LEARNED LESSONS - APPLY BEFORE ANYTHING ELSE

These lessons were extracted from past runs where mistakes were made.
Read every item. Do not repeat these mistakes.

$LessonsContent

---

"@
    }
}

# --- Open-PR cap guard (standing rule: <=1 open PR across GitHub) -------------
# Daily runs must not stack PRs. If an open PR already exists, force the agent
# into evaluation-only mode so it ends with NO SUBMISSION RECOMMENDED.
$OpenPrBlock = ""
try {
    # NOTE: Windows PowerShell 5.1 ConvertFrom-Json returns a JSON array as a
    # single object, so assign first then re-wrap with @() to get a real count.
    $openPrsRaw = gh search prs --author "TSS99" --state open --json url,title 2>$null | ConvertFrom-Json
    $openPrs = @($openPrsRaw)
    if ($openPrs.Count -ge 1) {
        $list = ($openPrs | ForEach-Object { "- $($_.title) ($($_.url))" }) -join "`n"
        $OpenPrBlock = @"
## HARD CONSTRAINT - OPEN PR CAP REACHED

You currently have $($openPrs.Count) open PR(s):
$list

The standing rule is a maximum of ONE open PR at a time. An open PR already
exists, so you MUST NOT open a new PR this run. You may evaluate and prepare,
but you MUST end with:

NO SUBMISSION RECOMMENDED

stating that the open-PR cap is the blocker.

---

"@
        Write-Host "Open-PR cap reached ($($openPrs.Count)) - agent in evaluation-only mode." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Warning: could not query open PRs ($_). Proceeding without guard." -ForegroundColor DarkYellow
}

$FullPrompt = $OpenPrBlock + $LessonsBlock + $BasePrompt

# --- Dry run -----------------------------------------------------------------

if ($DryRun) {
    Write-Host "=== DRY RUN: ASSEMBLED PROMPT ===" -ForegroundColor Cyan
    Write-Host $FullPrompt
    exit 0
}

# --- Setup run dir -----------------------------------------------------------

New-Item -ItemType Directory -Force -Path $RunDir | Out-Null
$FullPrompt | Out-File -FilePath (Join-Path $RunDir "prompt-used.md") -Encoding UTF8

function Log([string]$Msg, [string]$Color = "White") {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Msg" -ForegroundColor $Color
}

# --- Main contribution run ---------------------------------------------------

Log "Starting contribution agent (gpt-5.5, xhigh)..." "Cyan"
Log "Repo: $RepoPath" "Gray"
Log "Run:  $RunDir" "Gray"

$MainOutputFile = Join-Path $RunDir "output.txt"

# Pipe prompt via stdin - avoids command-line length limits on long prompts.
# codex reads stdin when no positional prompt argument is given.
$FullPrompt | codex exec `
    -m gpt-5.5 `
    -c "model_reasoning_effort=`"xhigh`"" `
    -s workspace-write `
    -C $RepoPath `
    -o $MainOutputFile

$MainExit = $LASTEXITCODE
if ($MainExit -eq 0) { Log "Main run exited: 0" "Green" } else { Log "Main run exited: $MainExit" "Red" }

# --- Read main output --------------------------------------------------------

if (Test-Path $MainOutputFile) {
    $MainOutput = Get-Content $MainOutputFile -Raw -Encoding UTF8
} else {
    $MainOutput = "(no output captured - codex may have written directly to stdout)"
}

$MainOutput | Out-File -FilePath (Join-Path $RunDir "summary.md") -Encoding UTF8

# --- Self-evaluation: extract lessons ----------------------------------------

Log "Running self-evaluation to extract lessons..." "Yellow"

if (Test-Path $LessonsFile) {
    $ExistingLessons = Get-Content $LessonsFile -Raw -Encoding UTF8
} else {
    $ExistingLessons = "(none yet)"
}

$SelfEvalPrompt = @"
You are reviewing your own performance as a Qiskit open-source contribution agent.

Below is the final output from your most recent run:

---
$MainOutput
---

Your task: extract concrete, actionable lessons from this run.

Rules:
1. Be brutally specific. "Be more careful" is worthless.
2. Focus on: wrong assumptions, rule violations, missed checks, unnecessary actions, near-misses, issues that nearly caused a bad PR.
3. Each lesson is one sentence starting with an imperative verb (e.g. "Verify", "Never", "Always", "Check").
4. Maximum 5 new lessons. Zero is fine if the run was clean.
5. Do NOT repeat lessons already in the existing list below.
6. If the run ended with NO SUBMISSION RECOMMENDED for the right reasons, note what gate caught it.

Existing lessons (do not duplicate):
$ExistingLessons

Output format - ONLY these lines, nothing else:
- [LESSON]: <lesson text>

If there are no new lessons worth adding, output exactly one line:
NO NEW LESSONS
"@

$LessonsOutputFile = Join-Path $RunDir "new-lessons.txt"

$SelfEvalPrompt | codex exec `
    -m gpt-5.5 `
    -c "model_reasoning_effort=`"xhigh`"" `
    -s workspace-write `
    -C $AgentDir `
    --ephemeral `
    -o $LessonsOutputFile

# --- Append new lessons ------------------------------------------------------

if (Test-Path $LessonsOutputFile) {
    $NewLessons = (Get-Content $LessonsOutputFile -Raw -Encoding UTF8).Trim()

    if ($NewLessons -and $NewLessons -ne "NO NEW LESSONS") {
        $RunDate = Get-Date -Format "yyyy-MM-dd HH:mm"
        $Entry   = "`n### Run $Timestamp ($RunDate)`n$NewLessons`n"

        if (-not (Test-Path $LessonsFile)) {
            "# Learned Lessons`n" | Out-File -FilePath $LessonsFile -Encoding UTF8
        }

        $Entry | Out-File -FilePath $LessonsFile -Append -Encoding UTF8
        Log "New lessons saved:" "Green"
        Write-Host $NewLessons -ForegroundColor Cyan
    } else {
        Log "No new lessons extracted." "Gray"
    }
} else {
    Log "Self-eval produced no output file." "DarkYellow"
}

# --- Push artifacts + lessons to private backup repo -------------------------

Log "Committing run artifacts to backup repo..." "Yellow"
git -C $AgentDir add -A 2>&1 | Out-Null
$CommitMsg = "Run $Timestamp (main exit $MainExit)"
git -C $AgentDir -c user.name="TSS99" -c user.email="tilock.2025@gmail.com" commit -m $CommitMsg 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    git -C $AgentDir push 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Log "Pushed to backup repo." "Green"
    } else {
        Log "Push failed - artifacts committed locally only." "Red"
    }
} else {
    Log "Nothing new to commit." "Gray"
}

# --- Done --------------------------------------------------------------------

Log "Done. Artifacts: $RunDir" "Cyan"
Log "Lessons file:    $LessonsFile" "Cyan"
