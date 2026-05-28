param(
    [switch]$Applet
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$BuildDir = Join-Path $Root "build"
$HostClasses = Join-Path $BuildDir "host-classes"
$AppletClasses = Join-Path $BuildDir "applet-classes"
$AppletConfig = Join-Path $BuildDir "applet-config"
$AppletDeliverables = Join-Path $BuildDir "applet-deliverables"

New-Item -ItemType Directory -Force $HostClasses | Out-Null
New-Item -ItemType Directory -Force $AppletClasses | Out-Null
New-Item -ItemType Directory -Force $AppletConfig | Out-Null
New-Item -ItemType Directory -Force $AppletDeliverables | Out-Null

Write-Host "Compiling host application..."
$hostSources = Get-ChildItem -Path (Join-Path $Root "src\host") -Recurse -Filter *.java |
    Where-Object { $_.Name -ne "SimulatorDeployAndRun.java" }
javac -d $HostClasses $hostSources.FullName

if ($Applet) {
    if (-not $env:JAVACARD_HOME) {
        throw "Set JAVACARD_HOME to the Java Card 3.2 SDK directory before compiling the applet."
    }

    $apiJar = Get-ChildItem -Path (Join-Path $env:JAVACARD_HOME "lib") -Filter "api_classic-3.2.0.jar" |
        Select-Object -First 1
    if (-not $apiJar) {
        throw "Could not find lib\api_classic-3.2.0.jar under JAVACARD_HOME."
    }

    Write-Host "Compiling Java Card applet with $($apiJar.FullName)..."
    $appletSources = Get-ChildItem -Path (Join-Path $Root "src\applet") -Recurse -Filter *.java
    javac -g -source 10 -target 10 -cp $apiJar.FullName -d $AppletClasses $appletSources.FullName

    $converter = Join-Path $env:JAVACARD_HOME "bin\converter.bat"
    if (-not (Test-Path $converter)) {
        throw "Could not find converter.bat under JAVACARD_HOME\bin."
    }

    if (-not $env:JAVA_HOME) {
        $javaHomeLine = java -XshowSettings:properties -version 2>&1 |
            Select-String -Pattern "^\s+java\.home\s+=" |
            Select-Object -First 1
        if ($javaHomeLine -and ($javaHomeLine.ToString() -match "java\.home\s+=\s+(.+)$")) {
            $env:JAVA_HOME = $Matches[1].Trim()
            Write-Host "JAVA_HOME was not set; using $env:JAVA_HOME"
        } else {
            throw "Set JAVA_HOME to a JDK 17 directory before running the Java Card converter."
        }
    }

    $configPath = Join-Path $AppletConfig "BlockchainWalletApplet.conf"
    @"
-i
-classdir $AppletClasses
-applet 0xF0:0x01:0x02:0x03:0x04:0x05:0x06 ro.ase.ism.blockchainwallet.BlockchainWalletApplet
-out CAP JCA EXP
-d $AppletDeliverables
-v
-debug
-target 3.2.0
ro.ase.ism.blockchainwallet
0xF0:0x01:0x02:0x03:0x04:0x05 1.0
"@ | Set-Content -Encoding ASCII $configPath

    Write-Host "Converting Java Card applet to CAP..."
    & $converter -config $configPath
    if ($LASTEXITCODE -ne 0) {
        throw "Java Card converter failed with exit code $LASTEXITCODE."
    }

    $capFile = Join-Path $AppletDeliverables "ro\ase\ism\blockchainwallet\javacard\blockchainwallet.cap"
    if (-not (Test-Path $capFile)) {
        throw "Java Card converter did not produce expected CAP file: $capFile"
    }
}

Write-Host "Build completed."
