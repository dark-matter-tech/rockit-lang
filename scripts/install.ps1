# Rockit — Windows Install Script
# Dark Matter Tech
#
# Usage (PowerShell):
#   irm https://rustygits.com/Dark-Matter/rockit-lang/raw/branch/develop/scripts/install.ps1 | iex

$ErrorActionPreference = "Stop"

$VERSION = "0.1.0"
$GITEA = "https://rustygits.com"
$REPO_LANG = "Dark-Matter/rockit-lang"
$REPO_COMPILER = "Dark-Matter/rockit-compiler"
$REPO_FUEL = "Dark-Matter/fuel"
$INSTALL_DIR = "$env:LOCALAPPDATA\Rockit\bin"
$SHARE_DIR = "$env:LOCALAPPDATA\Rockit\share\rockit"

$SIGNING_KEY_URL = "$GITEA/$REPO_LANG/raw/branch/develop/keys/darkmatter-release.asc"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Info($msg)  { Write-Host "==> $msg" }
function Write-Ok($msg)    { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "  [!]  $msg" -ForegroundColor Yellow }
function Write-Fail($msg)  { Write-Host "error: $msg" -ForegroundColor Red; exit 1 }

function Add-ToUserPath($dir) {
    if ($env:Path -notlike "*$dir*") {
        $env:Path = "$dir;$env:Path"
    }
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$dir*") {
        [Environment]::SetEnvironmentVariable("Path", "$dir;$userPath", "User")
        Write-Info "Added to PATH: $dir"
    }
}

function Set-UserEnvVar($name, $value) {
    [Environment]::SetEnvironmentVariable($name, $value, "User")
    [Environment]::SetEnvironmentVariable($name, $value, "Process")
    Write-Info "Set $name = $value"
}

function Test-CommandWorks($cmd) {
    try {
        $null = & $cmd --version 2>&1
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------

function Resolve-Architecture {
    if ([Environment]::Is64BitOperatingSystem) {
        Write-Ok "64-bit Windows"
        return "x86_64"
    }
    Write-Fail "32-bit Windows is not supported."
}

function Resolve-Winget {
    if (Get-Command winget -ErrorAction SilentlyContinue) { return }
    Write-Fail "winget (Windows Package Manager) is required but not found.`nIt ships with Windows 10 1809+ and Windows 11.`nInstall from: https://aka.ms/getwinget"
}

function Resolve-Git {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Ok "Git $(git --version 2>&1)"
        return
    }
    Write-Warn "Git not found. Installing via winget..."
    winget install Git.Git --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Ok "Git installed: $(git --version 2>&1)"
    } else {
        Write-Fail "Failed to install Git. Install manually from https://git-scm.com"
    }
}

function Resolve-Clang {
    if (Get-Command clang -ErrorAction SilentlyContinue) {
        Write-Ok "Clang $(clang --version 2>&1 | Select-Object -First 1)"
        return
    }
    $knownPaths = @(
        "C:\Program Files\LLVM\bin",
        "C:\Program Files (x86)\LLVM\bin",
        "$env:LOCALAPPDATA\LLVM\bin"
    )
    foreach ($p in $knownPaths) {
        if (Test-Path "$p\clang.exe") {
            Add-ToUserPath $p
            Write-Ok "Clang $(clang --version 2>&1 | Select-Object -First 1)"
            return
        }
    }
    Write-Warn "Clang not found. Installing LLVM via winget..."
    winget install LLVM.LLVM --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
    foreach ($p in $knownPaths) {
        if (Test-Path "$p\clang.exe") {
            Add-ToUserPath $p
            Write-Ok "LLVM installed: $(clang --version 2>&1 | Select-Object -First 1)"
            return
        }
    }
    Write-Fail "Failed to install LLVM.`nInstall manually: winget install LLVM.LLVM"
}

function Find-SwiftToolchain {
    $swiftBase = "$env:LOCALAPPDATA\Programs\Swift\Toolchains"
    if (-not (Test-Path $swiftBase)) { return $null }
    $versions = Get-ChildItem $swiftBase -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    foreach ($v in $versions) {
        $bin = Join-Path $v.FullName "usr\bin"
        if (Test-Path "$bin\swift.exe") { return $bin }
    }
    return $null
}

function Find-SwiftRuntime {
    $rtBase = "$env:LOCALAPPDATA\Programs\Swift\Runtimes"
    if (-not (Test-Path $rtBase)) { return $null }
    $versions = Get-ChildItem $rtBase -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    foreach ($v in $versions) {
        $bin = Join-Path $v.FullName "usr\bin"
        if (Test-Path "$bin\swiftCore.dll") { return $bin }
    }
    return $null
}

function Find-SwiftSDK {
    $platBase = "$env:LOCALAPPDATA\Programs\Swift\Platforms"
    if (-not (Test-Path $platBase)) { return $null }
    $versions = Get-ChildItem $platBase -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    foreach ($v in $versions) {
        $sdk = Join-Path $v.FullName "Windows.platform\Developer\SDKs\Windows.sdk"
        if (Test-Path $sdk) { return $sdk }
    }
    return $null
}

function Resolve-Swift {
    $needsInstall = $true
    if (Get-Command swift -ErrorAction SilentlyContinue) {
        if (Test-CommandWorks "swift") {
            Write-Ok "Swift $(swift --version 2>&1 | Select-Object -First 1)"
            $needsInstall = $false
        }
    }
    if ($needsInstall) {
        $tcBin = Find-SwiftToolchain
        $rtBin = Find-SwiftRuntime
        if ($tcBin) {
            Add-ToUserPath $tcBin
            if ($rtBin) { Add-ToUserPath $rtBin }
            if (Test-CommandWorks "swift") {
                Write-Ok "Swift $(swift --version 2>&1 | Select-Object -First 1)"
                $needsInstall = $false
            }
        }
    }
    if ($needsInstall) {
        Write-Warn "Swift not found. Installing via winget (this downloads ~850 MB)..."
        winget install Swift.Toolchain --accept-package-agreements --accept-source-agreements --skip-dependencies 2>&1 | Out-Null
        $tcBin = Find-SwiftToolchain
        $rtBin = Find-SwiftRuntime
        if (-not $tcBin) { Write-Fail "Failed to install Swift.`nInstall manually from https://swift.org/download" }
        Add-ToUserPath $tcBin
        if ($rtBin) { Add-ToUserPath $rtBin }
        if (Test-CommandWorks "swift") {
            Write-Ok "Swift installed: $(swift --version 2>&1 | Select-Object -First 1)"
        } else {
            Write-Fail "Swift installed but not functional.`nTry restarting your terminal."
        }
    }
    $sdkroot = [Environment]::GetEnvironmentVariable("SDKROOT", "User")
    if (-not $sdkroot -or -not (Test-Path $sdkroot -ErrorAction SilentlyContinue)) {
        $sdkroot = [Environment]::GetEnvironmentVariable("SDKROOT", "Machine")
    }
    if ($sdkroot -and (Test-Path $sdkroot -ErrorAction SilentlyContinue)) {
        $env:SDKROOT = $sdkroot
        Write-Ok "SDKROOT = $sdkroot"
    } else {
        $sdk = Find-SwiftSDK
        if ($sdk) {
            Set-UserEnvVar "SDKROOT" $sdk
            Write-Ok "SDKROOT = $sdk"
        } else {
            Write-Fail "Could not find Windows Swift SDK."
        }
    }
}

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------

function Import-SigningKey {
    if (-not (Get-Command gpg -ErrorAction SilentlyContinue)) {
        Write-Warn "gpg not found - cannot verify signatures"
        return $false
    }
    $tmpKey = Join-Path $env:TEMP "rockit-key-$(Get-Random).asc"
    try {
        Invoke-WebRequest -Uri $SIGNING_KEY_URL -OutFile $tmpKey -ErrorAction Stop
        gpg --import $tmpKey 2>$null
        Remove-Item $tmpKey -ErrorAction SilentlyContinue
        Write-Ok "Signing key imported"
        return $true
    } catch {
        Remove-Item $tmpKey -ErrorAction SilentlyContinue
        Write-Warn "Could not import signing key"
        return $false
    }
}

function Test-ManifestSignature($manifestPath) {
    $sigPath = "$manifestPath.sig"
    if (-not (Test-Path $sigPath)) { Write-Warn "No signature file found"; return $true }
    if (-not (Get-Command gpg -ErrorAction SilentlyContinue)) { Write-Warn "gpg not found"; return $true }
    Write-Info "Verifying manifest signature..."
    gpg --verify $sigPath $manifestPath 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Ok "Manifest signature: VALID"; return $true }
    else { Write-Fail "Manifest signature verification FAILED!"; return $false }
}

function Test-ManifestHashes($manifestPath, $baseDir) {
    if (-not (Test-Path $manifestPath)) { Write-Warn "No MANIFEST.sha256 found"; return $true }
    Write-Info "Verifying file integrity..."
    $failures = 0; $checked = 0
    foreach ($line in (Get-Content $manifestPath)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line -split '\s+', 2
        if ($parts.Count -lt 2) { continue }
        $expectedHash = $parts[0] -replace '^sha256:', ''
        $filePath = $parts[1]
        $fullPath = Join-Path $baseDir $filePath
        if (-not (Test-Path $fullPath)) { Write-Host "    MISSING: $filePath"; $failures++; continue }
        $actualHash = (Get-FileHash $fullPath -Algorithm SHA256).Hash.ToLower()
        if ($actualHash -eq $expectedHash) { $checked++ }
        else { Write-Host "    MISMATCH: $filePath"; $failures++ }
    }
    if ($failures -gt 0) { Write-Fail "Integrity check FAILED - $failures file(s) corrupted!" }
    Write-Ok "Integrity check passed ($checked files verified)"
    return $true
}

# ===========================================================================
# Main
# ===========================================================================

Write-Host ""
Write-Host "  Rockit Installer v$VERSION"
Write-Host "  Dark Matter Tech"
Write-Host ""

$arch = Resolve-Architecture
$platform = "windows-$arch"
$archive = "rockit-$VERSION-$platform.zip"
$url = "$GITEA/$REPO_LANG/releases/download/v$VERSION/$archive"

# --- Try prebuilt binary ---
Write-Info "Checking for prebuilt binary ($platform)..."

$tmp = Join-Path $env:TEMP "rockit-install-$(Get-Random)"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

$downloaded = $false
try {
    Invoke-WebRequest -Uri $url -OutFile "$tmp\$archive" -ErrorAction Stop
    $downloaded = $true
} catch {}

if ($downloaded) {
    Resolve-Winget
    Resolve-Clang

    Write-Info "Installing Rockit $VERSION..."
    Expand-Archive -Path "$tmp\$archive" -DestinationPath $tmp -Force

    $extracted = "$tmp\rockit-$VERSION-$platform\rockit"

    Import-SigningKey
    $manifestPath = "$extracted\MANIFEST.sha256"
    if (Test-Path $manifestPath) {
        Test-ManifestSignature $manifestPath
        Test-ManifestHashes $manifestPath $extracted
    }

    New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
    New-Item -ItemType Directory -Force -Path $SHARE_DIR | Out-Null
    Copy-Item "$extracted\bin\rockit.exe" "$INSTALL_DIR\rockit.exe" -Force
    Copy-Item "$extracted\bin\fuel.exe" "$INSTALL_DIR\fuel.exe" -Force -ErrorAction SilentlyContinue
    if (Test-Path "$extracted\share\rockit\rockit_runtime.o") {
        Copy-Item "$extracted\share\rockit\rockit_runtime.o" "$SHARE_DIR\rockit_runtime.o" -Force
    }
    if (Test-Path "$extracted\share\rockit\stdlib") {
        Copy-Item "$extracted\share\rockit\stdlib" "$SHARE_DIR\stdlib" -Recurse -Force
    }

    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    Write-Ok "Installed Rockit $VERSION ($platform)"
} else {
    # --- Build from source ---
    Write-Info "No prebuilt binary for $platform. Building from source..."
    Resolve-Winget
    Resolve-Git
    Resolve-Clang
    Resolve-Swift

    $savedEAP = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    Push-Location $env:TEMP

    # Clone compiler
    Write-Info "Downloading Rockit compiler..."
    git clone --depth 1 --recurse-submodules --branch develop "$GITEA/$REPO_COMPILER.git" "$tmp\compiler" 2>&1 | Out-Null

    # Clone Stage 0 bootstrap
    Write-Info "Downloading bootstrap compiler..."
    git clone --depth 1 --branch develop "$GITEA/Dark-Matter/rockit-booster.git" "$tmp\booster" 2>&1 | Out-Null

    Pop-Location

    # Build Stage 0
    Write-Info "Building bootstrap compiler..."
    Push-Location "$tmp\booster"
    swift build -c release 2>&1 | ForEach-Object { "$_" }
    Pop-Location

    # Build Stage 1
    Write-Info "Building compiler..."
    Push-Location "$tmp\compiler"
    bash src/build.sh 2>&1 | ForEach-Object { "$_" }
    & "$tmp\booster\.build\release\rockit.exe" build-native src/command.rok 2>&1 | ForEach-Object { "$_" }
    if ($LASTEXITCODE -ne 0) { Pop-Location; $ErrorActionPreference = $savedEAP; Write-Fail "Compiler build failed." }

    # Build Fuel
    Push-Location $env:TEMP
    Write-Info "Building Fuel package manager..."
    git clone --depth 1 --branch develop "$GITEA/$REPO_FUEL.git" "$tmp\fuel" 2>&1 | Out-Null
    Pop-Location

    if (Test-Path "$tmp\fuel\src\fuel.rok") {
        & "$tmp\compiler\src\command.exe" build-native "$tmp\fuel\src\fuel.rok" -o "$tmp\fuel\fuel.exe" --runtime-path "$tmp\compiler\runtime\rockit_runtime.o" 2>&1 | ForEach-Object { "$_" }
    }
    Pop-Location

    # Install
    New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
    New-Item -ItemType Directory -Force -Path $SHARE_DIR | Out-Null
    Copy-Item "$tmp\compiler\src\command.exe" "$INSTALL_DIR\rockit.exe" -Force
    if (Test-Path "$tmp\fuel\fuel.exe") { Copy-Item "$tmp\fuel\fuel.exe" "$INSTALL_DIR\fuel.exe" -Force }
    if (Test-Path "$tmp\compiler\runtime\rockit_runtime.o") {
        Copy-Item "$tmp\compiler\runtime\rockit_runtime.o" "$SHARE_DIR\rockit_runtime.o" -Force
    }
    if (Test-Path "$tmp\compiler\launchpad") {
        Copy-Item "$tmp\compiler\launchpad" "$SHARE_DIR\stdlib" -Recurse -Force
    }

    $ErrorActionPreference = $savedEAP
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    Write-Ok "Built and installed from source"
}

Add-ToUserPath $INSTALL_DIR

Write-Host ""
if (Get-Command rockit -ErrorAction SilentlyContinue) {
    Write-Ok "rockit installed: $(& rockit version 2>&1)"
} else {
    Write-Host "  Restart your terminal, then run: rockit version"
}
if (Get-Command fuel -ErrorAction SilentlyContinue) {
    Write-Ok "fuel installed: $(& fuel version 2>&1)"
}

Write-Host ""
Write-Host "  Get started:"
Write-Host "    fuel init my-app"
Write-Host "    cd my-app"
Write-Host "    fuel build"
Write-Host "    fuel run"
Write-Host ""
Write-Host "  Uninstall:"
Write-Host "    Remove-Item -Recurse -Force '$env:LOCALAPPDATA\Rockit'"
Write-Host ""
