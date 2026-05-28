param(
    [string]$Transaction = "bitcoin:from=alice;to=bob;amount=0.01000000;nonce=1",
    [int]$Port = 9025
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

if (-not $env:JC_HOME_SIMULATOR) {
    throw "Set JC_HOME_SIMULATOR to the Oracle Java Card simulator directory."
}

& (Join-Path $Root "scripts\build.ps1") -Applet

$AmService = Join-Path $env:JC_HOME_SIMULATOR "client\AMService\amservice.jar"
$SocketProvider = Join-Path $env:JC_HOME_SIMULATOR "client\COMService\socketprovider.jar"
$Props = Join-Path $Root "build\oracle-simulator-client.config.properties"
$ModulePath = "$AmService;$SocketProvider"

@"
A000000151000000_scp03enc_01=00000000000000000000000000000000
A000000151000000_scp03mac_01=00000000000000000000000000000000
A000000151000000_scp03dek_01=00000000000000000000000000000000
"@ | Set-Content -Encoding ASCII $Props

javac -d (Join-Path $Root "build\host-classes") `
    -cp (Join-Path $Root "build\host-classes") `
    -p $ModulePath `
    --add-modules ALL-MODULE-PATH `
    (Join-Path $Root "src\host\ro\ase\ism\blockchainwallet\host\SimulatorDeployAndRun.java")

java -cp (Join-Path $Root "build\host-classes") `
    -p $ModulePath `
    --add-modules ALL-MODULE-PATH `
    ro.ase.ism.blockchainwallet.host.SimulatorDeployAndRun `
    "--props=$Props" `
    "--port=$Port" `
    "--tx=$Transaction"
