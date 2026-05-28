param(
    [Parameter(Mandatory = $true)]
    [string]$LastName,

    [Parameter(Mandatory = $true)]
    [string]$FirstName,

    [string]$Assignment = "ASSIGNMENT6"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ZipName = "$LastName$FirstName" + "SPCEQ2026$Assignment.zip"
$ZipPath = Join-Path $Root $ZipName
$Stage = Join-Path $Root "build\package"

if (Test-Path $Stage) {
    Remove-Item -Recurse -Force $Stage
}

New-Item -ItemType Directory -Force $Stage | Out-Null
Copy-Item -Path (Join-Path $Root "README.md") -Destination $Stage
Copy-Item -Path (Join-Path $Root "src") -Destination $Stage -Recurse
Copy-Item -Path (Join-Path $Root "scripts") -Destination $Stage -Recurse
Copy-Item -Path (Join-Path $Root "docs") -Destination $Stage -Recurse

if (Test-Path $ZipPath) {
    Remove-Item -Force $ZipPath
}

Compress-Archive -Path (Join-Path $Stage "*") -DestinationPath $ZipPath
Write-Host "Created $ZipPath"
