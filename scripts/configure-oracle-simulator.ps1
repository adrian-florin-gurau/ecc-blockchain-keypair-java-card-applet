param(
    [string]$KeyVersionNumber = "01",
    [string]$EncKey = "00000000000000000000000000000000",
    [string]$MacKey = "00000000000000000000000000000000",
    [string]$DekKey = "00000000000000000000000000000000"
)

$ErrorActionPreference = "Stop"

if (-not $env:JC_HOME_SIMULATOR) {
    throw "Set JC_HOME_SIMULATOR to the Oracle Java Card simulator directory."
}

$Configurator = Join-Path $env:JC_HOME_SIMULATOR "tools\Configurator.jar"
$Simulator = Join-Path $env:JC_HOME_SIMULATOR "runtime\bin\jcsw.exe"

if (-not (Test-Path $Configurator)) {
    throw "Could not find Configurator.jar: $Configurator"
}

if (-not (Test-Path $Simulator)) {
    throw "Could not find simulator binary: $Simulator"
}

Write-Host "Configuring Oracle simulator SCP03 keys in:"
Write-Host $Simulator
Write-Host "Stop the simulator before running this script."

java -jar $Configurator `
    -binary $Simulator `
    -SCP-keyset $KeyVersionNumber $EncKey $MacKey $DekKey `
    -global-pin 000000000000 03 `
    -force

if ($LASTEXITCODE -ne 0) {
    throw "Configurator failed with exit code $LASTEXITCODE."
}

Write-Host "Simulator configured."
