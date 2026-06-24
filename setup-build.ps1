<#
.SYNOPSIS
    One-time build setup for the Qiskit contribution agent.

.DESCRIPTION
    Installs the Rust toolchain and builds Qiskit's _accelerate extension in the
    target clone so Stage 1/2 can import qiskit and reproduce issues. Run once;
    re-run after a rustup or clone reset. Idempotent.

.PARAMETER RepoPath
    Path to the local Qiskit git clone. Must match run.ps1's RepoPath.
#>
param(
    [string]$RepoPath = "D:\CDAC Projects\Qiskit_Advocate\qiskit"
)

Set-StrictMode -Version Latest
# This whole script drives native exes (winget, rustup, pip, cargo). In PS 5.1 a
# native command writing to stderr becomes a fatal NativeCommandError under "Stop"
# even on success (e.g. `rustup default stable` prints an info line to stderr), so
# stay on Continue and gate on exit codes / verification instead.
$ErrorActionPreference = "Continue"

if (-not (Test-Path (Join-Path $RepoPath ".git"))) {
    Write-Host "RepoPath is not a git checkout: $RepoPath" -ForegroundColor Red; exit 1
}

Write-Host "== 1/4 Rust toolchain ==" -ForegroundColor Cyan
# rustup installs to ~/.cargo/bin and updates the user PATH, but the current
# process may not see it yet; prepend it so cargo is usable this run.
$cargoBin = Join-Path $env:USERPROFILE ".cargo\bin"
if (Test-Path $cargoBin) { $env:Path = "$cargoBin;$env:Path" }
if (Get-Command cargo -ErrorAction SilentlyContinue) {
    Write-Host "cargo present: $(cargo --version)" -ForegroundColor Green
} else {
    Write-Host "Installing Rust via winget..." -ForegroundColor Yellow
    winget install --id Rustlang.Rustup -e --accept-source-agreements --accept-package-agreements
    if (Test-Path $cargoBin) { $env:Path = "$cargoBin;$env:Path" }
    rustup default stable
}

Write-Host "== 2/4 C++ Build Tools (linker for the Rust extension) ==" -ForegroundColor Cyan
# Building _accelerate needs the MSVC C++ toolchain (cl.exe / link.exe). Detect
# it via vswhere; if absent, install VS Build Tools with the VCTools workload.
$vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
$haveVc = $false
if (Test-Path $vswhere) {
    $vc = & $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
    if ($vc) { $haveVc = $true }
}
if ($haveVc) {
    Write-Host "MSVC C++ tools present." -ForegroundColor Green
} else {
    Write-Host "Installing VS Build Tools + C++ workload via winget (this is large)..." -ForegroundColor Yellow
    winget install --id Microsoft.VisualStudio.2022.BuildTools -e `
        --accept-source-agreements --accept-package-agreements `
        --override "--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
    Write-Host "If install opened a separate window, let it finish before the build step continues." -ForegroundColor DarkYellow
}

Write-Host "== 3/4 Build qiskit (_accelerate) ==" -ForegroundColor Cyan
Push-Location $RepoPath
try {
    pip install -e .
} finally { Pop-Location }

Write-Host "== 4/4 Verify gate ==" -ForegroundColor Cyan
Push-Location $RepoPath
try {
    cargo --version
    python -c "import qiskit._accelerate; print('qiskit._accelerate OK')"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Build gate PASSES. Agent unblocked - next run will reach Stage 1." -ForegroundColor Green
    } else {
        Write-Host "Build gate STILL FAILS - check errors above (likely missing C++ Build Tools)." -ForegroundColor Red
        Write-Host "Install: winget install Microsoft.VisualStudio.2022.BuildTools" -ForegroundColor Red
        Write-Host "  then add the 'Desktop development with C++' workload, and re-run this script." -ForegroundColor Red
    }
} finally { Pop-Location }
