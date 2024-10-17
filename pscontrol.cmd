

@echo off
if "%1"=="--unlock" (
    echo unlocking powershell scripts
	powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted"
	powershell -Command "Get-ExecutionPolicy"
) else (
    echo Locking powershell scripts
	powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted"
	powershell -Command "Get-ExecutionPolicy"
)