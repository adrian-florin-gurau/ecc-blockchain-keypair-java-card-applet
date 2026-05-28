param(
    [string]$Transaction = "bitcoin:from=alice;to=bob;amount=0.01000000;nonce=1"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

& (Join-Path $Root "scripts\build.ps1")
java -cp (Join-Path $Root "build\host-classes") ro.ase.ism.blockchainwallet.host.HostApp --card $Transaction
