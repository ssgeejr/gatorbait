Write-Host "[INIT] Verifying Gatorbait config file..."

$configPath = Join-Path $HOME ".gatorbait\gatorbait.cfg"
if (-not (Test-Path $configPath)) {
    Write-Error "[INIT] Config file not found: $configPath"
    exit 1
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json

Write-Host "`n[CONFIG] Loaded configuration:"
Write-Host "Host:     $($config.mysql.host)"
Write-Host "User:     $($config.mysql.user)"
Write-Host "Password: $($config.mysql.passwd)"
Write-Host "Database: $($config.mysql.db)"
Write-Host "Commit:   $($config.mysql.commit)"

# Continue with DLL install logic...

$libDir = Join-Path $PSScriptRoot "lib"
$mysqlDll = Join-Path $libDir "MySql.Data.dll"

if (-not (Test-Path $mysqlDll)) {
    Write-Host "[INIT] Downloading official MySql.Data from NuGet..."

    $nugetUrl = "https://www.nuget.org/api/v2/package/MySql.Data"
    $tempZip = "$env:TEMP\mysql.data.zip"
    $tempExtract = "$env:TEMP\mysql"

    Invoke-WebRequest -Uri $nugetUrl -OutFile $tempZip -UseBasicParsing
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

    $dllPath = Get-ChildItem -Recurse -Path $tempExtract -Filter "MySql.Data.dll" |
        Where-Object { $_.FullName -match "net45|netstandard2.0" } |
        Sort-Object Length -Descending |
        Select-Object -First 1

    if ($dllPath) {
        if (-not (Test-Path $libDir)) { New-Item -ItemType Directory -Path $libDir | Out-Null }
        Copy-Item $dllPath.FullName -Destination $mysqlDll -Force
        Write-Host "[INIT] MySql.Data.dll installed to: $mysqlDll"
    } else {
        Write-Error "[INIT] Could not find a usable MySql.Data.dll in the NuGet package."
        exit 1
    }

    # Optional cleanup
    Remove-Item -Force $tempZip -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $tempExtract -ErrorAction SilentlyContinue
} else {
    Write-Host "[INIT] Existing MySql.Data.dll found at: $mysqlDll"
}
Write-Host "[INIT] System compliant ... ready to go"