param(
    [string]$JavaHome = "C:\Program Files\Java\jdk-17",
    [string]$ToolsHome = "C:\Users\adrian\Desktop\java_card_devkit_tools-bin-v26.0-b_705-04-MAY-2026",
    [string]$SimulatorHome = "C:\Users\adrian\Desktop\java_card_devkit_simulator-win-bin-v26.0-b_788-05-MAY-2026"
)

$env:JAVA_HOME = $JavaHome
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
$env:JAVACARD_HOME = $ToolsHome
$env:JC_HOME_TOOLS = $ToolsHome
$env:JC_HOME_SIMULATOR = $SimulatorHome

Write-Host "JAVA_HOME=$env:JAVA_HOME"
Write-Host "JAVACARD_HOME=$env:JAVACARD_HOME"
Write-Host "JC_HOME_TOOLS=$env:JC_HOME_TOOLS"
Write-Host "JC_HOME_SIMULATOR=$env:JC_HOME_SIMULATOR"
Write-Host ""
Write-Host "Environment configured for this PowerShell session."
