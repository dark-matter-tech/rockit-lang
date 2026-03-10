# Rockit — Windows Uninstall Script
# Dark Matter Tech
#
# Usage (PowerShell):
#   irm https://rustygits.com/Dark-Matter/rockit-lang/raw/branch/develop/scripts/uninstall.ps1 | iex

$ErrorActionPreference = "Stop"

$INSTALL_DIR = "$env:LOCALAPPDATA\Rockit\bin"
$SHARE_DIR = "$env:LOCALAPPDATA\Rockit\share\rockit"
$ROCKIT_ROOT = "$env:LOCALAPPDATA\Rockit"

function Write-Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "  [!]  $msg" -ForegroundColor Yellow }

Write-Host ""
Write-Host "  Rockit Uninstaller"
Write-Host "  Dark Matter Tech"
Write-Host ""

$found = $false

if (Test-Path "$INSTALL_DIR\rockit.exe") {
    $found = $true
    Write-Host "  Found rockit at $INSTALL_DIR\rockit.exe"
}
if (Test-Path "$INSTALL_DIR\fuel.exe") {
    $found = $true
    Write-Host "  Found fuel at $INSTALL_DIR\fuel.exe"
}
if (Test-Path $SHARE_DIR) {
    $found = $true
    Write-Host "  Found shared data at $SHARE_DIR"
}

if (-not $found) {
    Write-Warn "Rockit does not appear to be installed at $ROCKIT_ROOT"
    Write-Host ""
    exit 0
}

Write-Host ""
Write-Host "  The following will be removed:"
Write-Host "    $ROCKIT_ROOT\"
Write-Host ""

$confirm = Read-Host "  Continue? [y/N]"
if ($confirm -ne "y") {
    Write-Host "  Cancelled."
    Write-Host ""
    exit 0
}

Write-Host ""

if (Test-Path $ROCKIT_ROOT) {
    Remove-Item -Recurse -Force $ROCKIT_ROOT
    Write-Ok "Removed $ROCKIT_ROOT"
}

# Remove from PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -like "*$INSTALL_DIR*") {
    $newPath = ($userPath -split ";" | Where-Object { $_ -ne $INSTALL_DIR }) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Ok "Removed $INSTALL_DIR from PATH"
}

Write-Host ""
Write-Ok "Rockit has been uninstalled."
Write-Host ""
