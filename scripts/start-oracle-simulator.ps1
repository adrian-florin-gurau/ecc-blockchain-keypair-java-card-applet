param(
    [int]$Port = 9025,
    [string]$LogLevel = "fine"
)

$ErrorActionPreference = "Stop"

if (-not $env:JC_HOME_SIMULATOR) {
    throw "Set JC_HOME_SIMULATOR to the Oracle Java Card Development Kit Simulator directory."
}

$Simulator = Join-Path $env:JC_HOME_SIMULATOR "runtime\bin\jcsw.exe"
if (-not (Test-Path $Simulator)) {
    throw "Could not find simulator executable: $Simulator"
}

Write-Host "Starting Oracle Java Card simulator on port $Port..."
Write-Host "Leave this window open while running scripts\run-oracle-simulator.ps1."

& $Simulator "-p=$Port" "-log_level=$LogLevel"
