# Define source and destination paths
$sourcePath = "C:\dloads\GatorBaitReport.ps1"
$destinationPath = Join-Path -Path $PSScriptRoot -ChildPath "GatorBaitReport.ps1"
Write-Host "Destination:     $destinationPath"
# Move the file, overwriting if it exists
Move-Item -Path $sourcePath -Destination $destinationPath -Force
Unblock-File -Path "C:\dev\wmmc\gatorbait\GatorBaitReport.ps1"
