<#
.SYNOPSIS
    Full installation script for mod-classless.
.DESCRIPTION
    This script automates the process of:
    1. Converting extracted DBCs to a SQLite database.
    2. Applying SQL patches to the database.
    3. Generating modified DBCs from the database.
    4. Deploying DBCs to the client (UIMods) and server.
    5. Creating an MPQ for the client.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$DbcInputPath, # Path to extracted DBFilesClient

    [string]$SqliteDbName = "wrath_dbcs.sqlite",
    
    [string]$ServerDbcPath = "$PSScriptRoot\..\..\cmake-build-debug-visual-studio\bin\Debug\dbc",
    
    [string]$MpqOutPath = "D:\CustomWowRebuild\patchn-new\patch-n.mpq",
    
    [string]$GameClientDataPath = "D:\CustomWowRebuild\GameClient\Data",
    
    [string]$MpqCliPath = "D:\CustomWowRebuild\Tools\mpqcli\mpqcli.exe",
    
    [string]$TempGenPath = "D:\CustomWowRebuild\patchn-new\gen"
)

$ErrorActionPreference = "Stop"

$ModuleRoot = $PSScriptRoot
$PatchGenDir = Join-Path $ModuleRoot "apps\patchgenerator"
$WowDbcDir = Join-Path $PatchGenDir "wow_dbc"
$SqliteDbPath = Join-Path $WowDbcDir $SqliteDbName
$UIModsPath = Join-Path $ModuleRoot "UIMods\patch-n"

Write-Host "--- Phase 1: Creating SQLite Database ---" -ForegroundColor Cyan
Push-Location $WowDbcDir
try {
    cargo run -p wow_dbc_converter -- wrath -i "$DbcInputPath" -o "$SqliteDbName"
} finally {
    Pop-Location
}

Write-Host "`n--- Phase 2: Applying SQL Patches ---" -ForegroundColor Cyan
Push-Location $PatchGenDir
try {
    .\apply_patches.ps1 -SqliteDb "$SqliteDbPath"
} finally {
    Pop-Location
}

Write-Host "`n--- Phase 3: Generating DBCs ---" -ForegroundColor Cyan
if (!(Test-Path $TempGenPath)) {
    New-Item -ItemType Directory -Path $TempGenPath -Force | Out-Null
}
Push-Location $WowDbcDir
try {
    # Using the required dmls as input for wow_custom_dbc as per README
    $DmlsRequired = Join-Path $PatchGenDir "dmls\required"
    cargo run -p wow_custom_dbc -- wrath -o "$TempGenPath" -i "$DmlsRequired"
} finally {
    Pop-Location
}

Write-Host "`n--- Phase 4: Deploying DBCs ---" -ForegroundColor Cyan
$GenDbcPath = Join-Path $TempGenPath "dbc"
$TargetUIModDbcPath = Join-Path $UIModsPath "DBFilesClient"

Write-Host "Copying to UIMods..."
if (!(Test-Path $TargetUIModDbcPath)) {
    New-Item -ItemType Directory -Path $TargetUIModDbcPath -Force | Out-Null
}
Copy-Item -Path "$GenDbcPath\*" -Destination $TargetUIModDbcPath -Force

Write-Host "Copying to Worldserver..."
if (!(Test-Path $ServerDbcPath)) {
    New-Item -ItemType Directory -Path $ServerDbcPath -Force | Out-Null
}
Copy-Item -Path "$GenDbcPath\*" -Destination $ServerDbcPath -Force

Write-Host "`n--- Phase 5: Generating MPQ ---" -ForegroundColor Cyan
if (Test-Path $MpqOutPath) {
    Remove-Item $MpqOutPath -Force
}

$MpqDir = [System.IO.Path]::GetDirectoryName($MpqOutPath)
if (!(Test-Path $MpqDir)) {
    New-Item -ItemType Directory -Path $MpqDir -Force | Out-Null
}

& $MpqCliPath create -o "$MpqOutPath" "$UIModsPath"

Write-Host "Copying MPQ to Game Client..."
if (!(Test-Path $GameClientDataPath)) {
    Write-Warning "Game client data path not found: $GameClientDataPath. Skipping copy."
} else {
    Copy-Item -Path $MpqOutPath -Destination $GameClientDataPath -Force
}

Write-Host "`nInstallation complete!" -ForegroundColor Green
