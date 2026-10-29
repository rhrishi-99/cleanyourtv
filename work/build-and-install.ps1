# Rebuild the launcher from launcher\ (after editing launcher\app\src\main\res\values\config.xml) and install
# it on the TV as Home, with the portable JDK 17 and Android SDK set up on 2026-10-29. From the repo root:
#
#   powershell -ExecutionPolicy Bypass -File work\build-and-install.ps1 -TvHost <tv ip>
#
# Needs ADB on the TV (USB debugging on, see work\README.md).
param([string]$TvHost = $env:TV_HOST)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
if (-not $TvHost) { throw 'pass -TvHost <tv ip> or set $env:TV_HOST' }
if (-not $env:JAVA_HOME) {
    $jdk = Get-ChildItem "$env:LOCALAPPDATA\cleanyourtv-jdk17" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $jdk) { throw "no JDK 17 in $env:LOCALAPPDATA\cleanyourtv-jdk17; set JAVA_HOME to a JDK 17 to 22 (work\README.md, Rebuilding)" }
    $env:JAVA_HOME = $jdk.FullName
}
if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk" }
& powershell -ExecutionPolicy Bypass -File (Join-Path $repo 'launcher\build-and-install.ps1') -TvHost $TvHost
if ($LASTEXITCODE -ne 0) { throw 'launcher\build-and-install.ps1 failed; see above' }
