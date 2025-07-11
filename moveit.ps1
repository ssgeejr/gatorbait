# Define source and destination paths
$sourcePath = "C:\dloads\GatorBait.ps1"
$destinationPath = Join-Path -Path $PSScriptRoot -ChildPath "GatorBait.ps1"
Write-Host "Destination:     $destinationPath"
# Move the file, overwriting if it exists
Move-Item -Path $sourcePath -Destination $destinationPath -Force
Unblock-File -Path "C:\dev\wmmc\gatorbait\GatorBait.ps1"
