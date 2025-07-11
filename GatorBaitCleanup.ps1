Write-Host "[CLEANUP] Starting burn-it-down cleanup..."

$libDll = Join-Path $PSScriptRoot "lib\MySql.Data.dll"
$tempZip = "$env:TEMP\mysql.data.zip"
$tempExtract = "$env:TEMP\mysql"

# Delete DLL
if (Test-Path $libDll) {
    Remove-Item $libDll -Force
    Write-Host "[CLEANUP] Deleted: $libDll"
} else {
    Write-Host "[CLEANUP] DLL not found: $libDll"
}

# Delete temp NuGet .zip
if (Test-Path $tempZip) {
    Remove-Item $tempZip -Force
    Write-Host "[CLEANUP] Deleted: $tempZip"
}

# Delete extracted NuGet temp folder
if (Test-Path $tempExtract) {
    Remove-Item $tempExtract -Recurse -Force
    Write-Host "[CLEANUP] Deleted: $tempExtract"
}

Write-Host "[CLEANUP] Completed cleanup successfully."
