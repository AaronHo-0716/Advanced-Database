# reset.ps1 — Windows PowerShell twin of reset.sh.
# Keep behaviorally identical to reset.sh: any change here must be mirrored there.

$ErrorActionPreference = "Stop"

# load .env
if (-not (Test-Path ".env")) {
    Write-Error "ERROR: .env not found. Copy .env.example to .env first."
    exit 1
}
Get-Content ".env" | ForEach-Object {
    if ($_ -match '^\s*#') { return }
    if ($_ -match '^\s*$') { return }
    $parts = $_ -split '=', 2
    if ($parts.Count -eq 2) {
        $name = $parts[0].Trim()
        $value = $parts[1].Trim().Trim('"')
        Set-Item -Path "Env:$name" -Value $value
    }
}

$SaPass = $env:MSSQL_SA_PASSWORD
$Db = if ($env:DB_NAME) { $env:DB_NAME } else { "glcl" }

function Get-SqlcmdPath {
    $candidate18 = docker exec glcl-mssql test -x /opt/mssql-tools18/bin/sqlcmd 2>$null
    if ($LASTEXITCODE -eq 0) { return "/opt/mssql-tools18/bin/sqlcmd" }
    $candidate = docker exec glcl-mssql test -x /opt/mssql-tools/bin/sqlcmd 2>$null
    if ($LASTEXITCODE -eq 0) { return "/opt/mssql-tools/bin/sqlcmd" }
    return $null
}

Write-Host ">> tearing down (wiping volume for clean state)"
docker compose down -v

Write-Host ">> starting SQL Server"
docker compose up -d

Write-Host ">> resolving sqlcmd path inside container"
$Sqlcmd = $null
while (-not $Sqlcmd) {
    $Sqlcmd = Get-SqlcmdPath
    if (-not $Sqlcmd) { Write-Host -NoNewline "."; Start-Sleep -Seconds 2 }
}
Write-Host " using $Sqlcmd"

Write-Host ">> waiting for SQL Server to accept connections"
while ($true) {
    try {
        docker exec glcl-mssql $Sqlcmd -S localhost -U sa -P $SaPass -C -Q "SELECT 1" *> $null
        if ($LASTEXITCODE -eq 0) { break }
    }
    catch {
        # SQL Server not ready yet, keep waiting
    }

    Write-Host -NoNewline "."
    Start-Sleep -Seconds 2
}
Write-Host " ready."

Write-Host ">> creating database $Db"
docker exec glcl-mssql $Sqlcmd -S localhost -U sa -P $SaPass -C `
    -Q "IF DB_ID('$Db') IS NULL CREATE DATABASE [$Db];"

Write-Host ">> applying schema scripts"
Get-ChildItem -Path "schema" -Filter "*.sql" | Sort-Object Name | ForEach-Object {
    Write-Host "   applying schema/$($_.Name)"
    Get-Content $_.FullName -Raw | docker exec -i glcl-mssql $Sqlcmd -S localhost -U sa -P $SaPass -C -d $Db -i /dev/stdin
}

Write-Host ">> done. Database '$Db' is rebuilt and seeded."
