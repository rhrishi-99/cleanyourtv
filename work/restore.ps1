# Undo everything done to this TV (Xiaomi MiTV-AXSO0) on 2026-10-29: re-enables the 27 packages in
# work\debloat.txt and the stock launcher, gives Home back to the stock launcher, and puts Private DNS back
# to automatic. Needs ADB on the TV (USB debugging on, see work\README.md). From the repo root:
#
#   powershell -ExecutionPolicy Bypass -File work\restore.ps1 -TvHost <tv ip>
#   [-KeepDns]         leave the AdGuard Private DNS on
#   [-RemoveLauncher]  also uninstall the new launcher (com.gathin.tvhome) once the stock one is Home again
param(
    [string]$TvHost = $env:TV_HOST,
    [switch]$KeepDns,
    [switch]$RemoveLauncher
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
if (-not $TvHost) { throw 'pass -TvHost <tv ip> or set $env:TV_HOST' }
$env:TV_HOST = $TvHost
$py = Join-Path $repo 'tools\venv\Scripts\python.exe'
$tv = Join-Path $repo 'tools\tv.py'
$homeQuery = 'cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME'

# Packages, the stock launcher and Home, replayed from the record tools\disable.ps1 wrote before the first
# change (~\.cleanyourtv\recovery-*.json, copy in backup\).
& powershell -ExecutionPolicy Bypass -File (Join-Path $repo 'tools\restore.ps1') -TvHost $TvHost (Join-Path $PSScriptRoot 'debloat.txt')
if ($LASTEXITCODE -ne 0) { throw 'tools\restore.ps1 failed; see above' }

if (-not $KeepDns) {
    # Both keys were unset (automatic) before; deleting them puts that back exactly.
    & $py -I $tv 'settings delete global private_dns_mode; settings delete global private_dns_specifier; echo Private DNS back to automatic'
}

$homeNow = "$(& $py -I $tv $homeQuery | Select-Object -Last 1)".Trim()
Write-Host "Home now resolves to $homeNow"
if ($RemoveLauncher) {
    # Only once the stock launcher owns Home, so the TV is never left without one.
    if ($homeNow -notlike 'com.google.android.tvlauncher/*') { throw "Home is '$homeNow', not the stock launcher; the new launcher was left installed" }
    & $py -I $tv 'pm uninstall com.gathin.tvhome'
}
