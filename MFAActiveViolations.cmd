echo unlocking powershell script authority
@echo off
powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted"
powershell -Command "Get-ExecutionPolicy"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ".\MFAActiveViolations.ps1"
::echo %$date%
:: Confirm completion
echo Export completed, results saved to: withOutMFAOnly_%$date%.csv


echo Revoking powershell script authority
powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted"
powershell -Command "Get-ExecutionPolicy"