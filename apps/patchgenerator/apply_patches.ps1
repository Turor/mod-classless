<#
.SYNOPSIS
    Applies classless DBC SQLite patches with Flyway.
.DESCRIPTION
    Downloads the Flyway CLI on first run if needed, then migrates
    wrath_dbcs.sqlite using versioned SQL in dmls/migrations.
#>

param (
    [string]$SqliteDb = "./wow_dbc/wrath_dbcs.sqlite",
    [string]$FlywayVersion = "11.10.1"
)

$ErrorActionPreference = "Stop"
$BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not [System.IO.Path]::IsPathRooted($SqliteDb)) {
    $SqliteDb = Join-Path $BaseDir $SqliteDb
}

if (-not (Test-Path $SqliteDb)) {
    Write-Error "SQLite database not found: $SqliteDb"
}

$FlywayHome = Join-Path $BaseDir ".flyway\flyway-$FlywayVersion"
$FlywayCmd = Join-Path $FlywayHome "flyway.cmd"

function Ensure-Flyway {
    if (Test-Path $FlywayCmd) {
        return
    }
    $onPath = Get-Command flyway -ErrorAction SilentlyContinue
    if ($onPath) {
        $script:FlywayCmd = $onPath.Source
        return
    }

    $dest = Join-Path $BaseDir ".flyway"
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    $archive = "flyway-commandline-$FlywayVersion-windows-x64.zip"
    $url = "https://download.red-gate.com/maven/release/com/redgate/flyway/flyway-commandline/$FlywayVersion/$archive"
    $zipPath = Join-Path $dest $archive
    Write-Host "Downloading Flyway $FlywayVersion..."
    Invoke-WebRequest -Uri $url -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $dest -Force
    Remove-Item $zipPath
}

Ensure-Flyway

# Forward slashes keep the JDBC URL valid on Windows.
$jdbcPath = ($SqliteDb -replace '\\', '/')
$jdbcUrl = "jdbc:sqlite:$jdbcPath"

Write-Host "Migrating $SqliteDb with Flyway..." -ForegroundColor Cyan
& $FlywayCmd `
    "-configFiles=$BaseDir\flyway.conf" `
    "-workingDirectory=$BaseDir" `
    "-url=$jdbcUrl" `
    migrate

if ($LASTEXITCODE -ne 0) {
    Write-Error "Flyway migrate failed with exit code $LASTEXITCODE"
}

Write-Host "Finished applying patches." -ForegroundColor Yellow
