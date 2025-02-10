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
::      echo File withOutMFAOnly_%$date%.csv deleted successfully ...
:: else (
::    echo Failed to find file: withOutMFAOnly_%$date%.csv ...
:: )
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ".\Get-MFAStatus.ps1 -withOutMFAOnly | Export-Csv -Path 'withOutMFAOnly_%$date%.csv' -NoTypeInformation"
::echo %$date%
:: Confirm completion
:: echo Export completed, results saved to: withOutMFAOnly_%$date%.csv


setlocal enabledelayedexpansion

set filename=withOutMFAOnly_%$date%.csv	
set targetdir=..\ceres

mv "%filename%" "%targetdir%"
if errorlevel 1 (
    echo Failed to move the file: %filename%
    exit /b 1
)

cd "%targetdir%"
if errorlevel 1 (
    echo Failed to change directory to: %targetdir%
    exit /b 1
)

python Ceres.py -f "%filename%"
if errorlevel 1 (
    echo Failed to execute Ceres.py with the file: %filename%
    exit /b 1
)


:: echo Revoking powershell script authority
powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted"
:: powershell -Command "Get-ExecutionPolicy"
