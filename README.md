# gatorbait
cybersecurity tools

https://learn.microsoft.com/en-us/answers/questions/1226005/azure-cloud-shell-the-term-get-msoluser-is-not-rec


Use this one instead
Install-Module MSOnline -Force

Connect-MsolService

NOW USE YOUR COMMANDS .... 



*NOT recommended*
Install-Module -Name AzureAD
Import-Module -Name AzureAD


Import-Module -Name AzureAD -Force

To enable users to execute ps1 scripts:
go to system settings -> Update & Security -> For Developers -> PowerShell

as admin: 
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted

>>> https://admindroid.com/how-to-get-mfa-disabled-users-report-in-microsoft-365

Get-MsolUser -all | select DisplayName,UserPrincipalName,@{N= "MFAStatus"; E ={if( $_.StrongAuthenticationRequirements.State -ne $null) {$_.StrongAuthenticationRequirements.State} else {"Disabled" }}} | where MFAStatus -eq "Disabled" 



If you encounter execution policy restrictions, you might need to set an appropriate execution policy, like Set-ExecutionPolicy RemoteSigned, or run the script with the policy temporarily bypassed using:
	powershell -ExecutionPolicy Bypass -File ".\CheckUsersWithoutMFA.ps1".



-withOutMFAOnly

Get-MFAStatus.ps1 -withOutMFAOnly