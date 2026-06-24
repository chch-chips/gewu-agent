$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot
$PidFile = Join-Path $Root ".run\gewu-agent-dev.pid"
$LauncherPidFile = Join-Path $Root ".run\gewu-agent-dev-launcher.pid"

if (-not (Test-Path -LiteralPath $PidFile) -and -not (Test-Path -LiteralPath $LauncherPidFile)) {
    Write-Host "Gewu Agent backend dev server is not running. PID files not found."
    exit 0
}

$pids = @()
foreach ($file in @($PidFile, $LauncherPidFile)) {
    if (-not (Test-Path -LiteralPath $file)) {
        continue
    }

    $pidText = (Get-Content -LiteralPath $file -Raw).Trim()
    if ($pidText -match "^\d+$") {
        $pids += [int]$pidText
    }
}

$stopped = @()
foreach ($processId in ($pids | Select-Object -Unique)) {
    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if (-not $process) {
        continue
    }

    taskkill.exe /PID $process.Id /T /F | Out-Null
    $stopped += $process.Id
}

Remove-Item -LiteralPath $PidFile, $LauncherPidFile -Force -ErrorAction SilentlyContinue

if ($stopped.Count -eq 0) {
    Write-Host "Gewu Agent backend dev server was not running. Removed stale PID files."
}
else {
    Write-Host "Gewu Agent backend dev server stopped. PID: $($stopped -join ', ')"
}
