echo unlocking powershell script authority
@echo off
powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted"
powershell -Command "Get-ExecutionPolicy"

:: Get the current date in MMDDYY format
for /f "tokens=2-4 delims=/-" %%a in ('date /t') do (
    set MMDDYY=%%a%%b%%c
)
:: Trim any possible trailing spaces (for safety)
set MMDDYY=%MMDDYY: =%

:: Verify the date format (MMDDYY)
:: echo export file set to: withOutMFAOnly_%MMDDYY%.csv

:: Execute the PowerShell script and generate the output file
:: .\Get-MFAStatus.ps1 -withOutMFAOnly | Export-CSV withOutMFAOnly_%MMDDYY%.csv -noTypeInformation
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ".\Get-MFAStatus.ps1 -withOutMFAOnly | Export-Csv -Path 'withOutMFAOnly_%MMDDYY%.csv' -NoTypeInformation"

:: Confirm completion
echo Export completed, results saved to: withOutMFAOnly_%MMDDYY%.csv

echo Revoking powershell script authority
powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted"
powershell -Command "Get-ExecutionPolicy"
