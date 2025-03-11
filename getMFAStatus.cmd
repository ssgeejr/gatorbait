:: echo unlocking powershell script authority
@echo off
powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted"
:: powershell -Command "Get-ExecutionPolicy"

:: Get the current date in MMDDYY format
set "$date=%date:~4%"
set "$date=%$date:/=%"


:: Verify the date format (MMDDYY)
:: echo export file set to: withOutMFAOnly_%MMDDYY%.csv

:: Execute the PowerShell script and generate the output file
:: .\Get-MFAStatus.ps1 -withOutMFAOnly | Export-CSV withOutMFAOnly_%MMDDYY%.csv -noTypeInformation

if exist withOutMFAOnly_%$date%.csv (
 	del /Q withOutMFAOnly_%$date%.csv
)

echo

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ".\Get-MFAStatus.ps1 -withOutMFAOnly | Export-Csv -Path 'withOutMFAOnly_%$date%.csv' -NoTypeInformation"

cd ..\ceres

python Ceres.py -f "%filename%"
if errorlevel 1 (
    echo Failed to execute Ceres.py with the file: %filename%
    exit /b 1
)

:: echo Revoking powershell script authority
powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted"
:: powershell -Command "Get-ExecutionPolicy"

exit 

setlocal enabledelayedexpansion

set filename=withOutMFAOnly_%$date%.csv
set targetdir=..\ceres\



echo %filename%
echo copy to 
echo %targetdir%


copy withOutMFAOnly_%$date%.csv %targetdir%
if errorlevel 1 (
    echo "'Failed to copy the file: %filename%'"
	type errorlog.txt
    exit /b 1
)

cd "%targetdir%"
if errorlevel 1 (
    echo Failed to change directory to: %targetdir%
	type errorlog.txt
    exit /b 1
)

:: python Ceres.py -f "%filename%"
echo **** simulation under way ****
if errorlevel 1 (
    echo Failed to execute Ceres.py with the file: %filename%
    exit /b 1
)


:: echo Revoking powershell script authority
powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted"
:: powershell -Command "Get-ExecutionPolicy"
