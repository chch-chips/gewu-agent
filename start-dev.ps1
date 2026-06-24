param(
    [int]$Port = 8080,
    [switch]$Background
)

$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot
$RunDir = Join-Path $Root ".run"
$LogDir = Join-Path $RunDir "logs"
$PidFile = Join-Path $RunDir "gewu-agent-dev.pid"
$LauncherPidFile = Join-Path $RunDir "gewu-agent-dev-launcher.pid"
$LauncherScript = Join-Path $RunDir "gewu-agent-dev-launcher.ps1"
$OutLog = Join-Path $LogDir "backend-dev.out.log"
$ErrLog = Join-Path $LogDir "backend-dev.err.log"
$LocalRepo = Join-Path $Root ".m2\repository"

New-Item -ItemType Directory -Force -Path $RunDir, $LogDir, $LocalRepo | Out-Null

function Get-RunningProcess {
    foreach ($file in @($PidFile, $LauncherPidFile)) {
        if (-not (Test-Path -LiteralPath $file)) {
            continue
        }

        $pidText = (Get-Content -LiteralPath $file -Raw).Trim()
        if (-not ($pidText -match "^\d+$")) {
            continue
        }

        $process = Get-Process -Id ([int]$pidText) -ErrorAction SilentlyContinue
        if ($process) {
            return $process
        }
    }
    return $null
}

function Get-JavaMajorVersion {
    param([string]$JavaExe)

    if (-not (Test-Path -LiteralPath $JavaExe)) {
        return $null
    }

    $versionOutput = & cmd.exe /d /c "`"$JavaExe`" -version 2>&1"
    $versionLine = $versionOutput | Select-Object -First 1
    if ($versionLine -match 'version "(\d+)') {
        return [int]$Matches[1]
    }
    return $null
}

function Resolve-Jdk21 {
    $candidates = @()

    if ($env:JAVA_HOME) {
        $candidates += $env:JAVA_HOME
    }

    $candidateRoots = @(
        "$env:USERPROFILE\.jdks",
        "C:\Program Files\Java",
        "D:\Program Files\Java",
        "C:\Program Files\Eclipse Adoptium",
        "C:\Program Files\Microsoft\jdk"
    )

    foreach ($candidateRoot in $candidateRoots) {
        if (Test-Path -LiteralPath $candidateRoot) {
            $candidates += Get-ChildItem -LiteralPath $candidateRoot -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match "21" } |
                Sort-Object Name -Descending |
                ForEach-Object { $_.FullName }
        }
    }

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        $javaExe = Join-Path $candidate "bin\java.exe"
        if ((Get-JavaMajorVersion $javaExe) -eq 21) {
            return $candidate
        }
    }

    throw "JDK 21 was not found. Install JDK 21 or set JAVA_HOME to a JDK 21 directory."
}

function Reset-LogFile {
    param(
        [string]$Path,
        [string]$Prefix,
        [string]$Extension
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $Path
    }

    try {
        Remove-Item -LiteralPath $Path -Force
        return $Path
    }
    catch {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        return Join-Path $LogDir "$Prefix-$timestamp.$Extension"
    }
}

$running = Get-RunningProcess
if ($running) {
    Write-Host "Gewu Agent backend dev server is already running. PID: $($running.Id)"
    Write-Host "URL: http://localhost:$Port"
    Write-Host "Logs: $OutLog"
    exit 0
}

Remove-Item -LiteralPath $PidFile, $LauncherPidFile -Force -ErrorAction SilentlyContinue

$jdkHome = Resolve-Jdk21
$mvn = (Get-Command mvn -ErrorAction Stop).Source

$OutLog = Reset-LogFile -Path $OutLog -Prefix "backend-dev" -Extension "out.log"
$ErrLog = Reset-LogFile -Path $ErrLog -Prefix "backend-dev" -Extension "err.log"

$env:JAVA_HOME = $jdkHome
$env:Path = "$jdkHome\bin;$env:Path"

if (-not $Background) {
    Write-Host "Starting Gewu Agent backend in foreground mode..."
    Write-Host "Press Ctrl+C to stop."
    Write-Host ""
    & "$mvn" "-Dmaven.repo.local=$LocalRepo" "spring-boot:run" "-Dspring-boot.run.arguments=--server.port=$Port"
    exit $LASTEXITCODE
}

$launcherContent = @"
`$ErrorActionPreference = "Stop"
Set-Location -LiteralPath "$Root"
`$env:JAVA_HOME = "$jdkHome"
`$env:Path = "`$env:JAVA_HOME\bin;`$env:Path"
& "$mvn" "-Dmaven.repo.local=$LocalRepo" "spring-boot:run" "-Dspring-boot.run.arguments=--server.port=$Port" 1>> "$OutLog" 2>> "$ErrLog"
"@
$launcherContent | Set-Content -LiteralPath $LauncherScript -Encoding utf8

$process = Start-Process `
    -FilePath "powershell.exe" `
    -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $LauncherScript) `
    -WorkingDirectory $Root `
    -WindowStyle Hidden `
    -PassThru

$process.Id | Set-Content -LiteralPath $LauncherPidFile -Encoding ascii
$process.Id | Set-Content -LiteralPath $PidFile -Encoding ascii

$started = $false
$appPid = $null
for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Seconds 1
    if (Test-Path -LiteralPath $OutLog) {
        $log = Get-Content -LiteralPath $OutLog -Raw -ErrorAction SilentlyContinue
        if ($log -match "Started GewuAgentApplication") {
            if ($log -match "with PID (\d+)") {
                $appPid = [int]$Matches[1]
                $appPid | Set-Content -LiteralPath $PidFile -Encoding ascii
            }
            $started = $true
            break
        }
    }
    $process.Refresh()
    if ($process.HasExited) {
        break
    }
}

if (-not $started) {
    Remove-Item -LiteralPath $PidFile, $LauncherPidFile -Force -ErrorAction SilentlyContinue
    Write-Host "Gewu Agent backend dev server failed to start. See logs:"
    Write-Host $OutLog
    Write-Host $ErrLog
    exit 1
}

Write-Host "Gewu Agent backend dev server started."
Write-Host "PID: $appPid"
Write-Host "Launcher PID: $($process.Id)"
Write-Host "URL: http://localhost:$Port"
Write-Host "Profile: dev"
Write-Host "Logs: $OutLog"
Write-Host ""
Write-Host "Startup summary:"
Get-Content -LiteralPath $OutLog |
    Select-String -Pattern "Starting GewuAgentApplication|Tomcat started|Started GewuAgentApplication|DeepSeek config" |
    Select-Object -Last 8 |
    ForEach-Object { Write-Host $_.Line }
