# gatorbait
cybersecurity tools

Unblock-File -Path "C:\dev\wmmc\gatorbait\GatorBait.ps1"



💡 Option: Use PdfSharp with PowerShell
Here’s how to do it:

1. Download PdfSharp.dll
Get it from NuGet:
https://www.nuget.org/packages/PDFsharp/1.50.5147
Or direct:
Download PDFsharp-MigraDoc Foundation

Extract and copy PdfSharp.dll to your gatorbait\lib\ folder.


https://www.nuget.org/downloads

PS C:\dloads> nuget sources Add -Name "nuget.org" -Source "https://api.nuget.org/v3/index.json"
Package source with Name: nuget.org added successfully.



https://lazyadmin.nl/powershell/list-office365-mfa-status-powershell/

File: https://github.com/ruudmens/LazyAdmin/blob/master/Office365/MFAStatus.ps1

#get details by user
Get-MFAStatus.ps1 -UserPrincipalName 'johndoe@contoso.com'

#to export 
	Get-MFAStatus.ps1 -UserPrincipalName 'johndoe@contoso.com' | Export-CSV mfasearch.csv -noTypeInformation


#Getting a list of all users and their MFA Status
Get-MFAStatus.ps1 | Export-CSV c:\temp\mfastatus.csv -noTypeInformation

#Get only the users without MFA
	Get-MFAStatus.ps1 -withOutMFAOnly | Export-CSV withOutMFAOnly.csv -noTypeInformation




## ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


https://learn.microsoft.com/en-us/answers/questions/1226005/azure-cloud-shell-the-term-get-msoluser-is-not-rec


GETTING USER EMAIL RULES 
Install-Module -Name ExchangeOnlineManagement


see email rules with powershell 

Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName <YourAdminAccount@YourDomain.com>

Get-InboxRule -Mailbox <UserEmail>

Grab and export: 
Get-InboxRule -Mailbox <UserEmail> | Select-Object Name, Description, Priority, Enabled, Conditions, Actions | Format-Table -AutoSize

Optional: 

Get-InboxRule -Mailbox <UserEmail> | Export-Csv -Path "C:\Path\To\Save\UserInboxRules.csv" -NoTypeInformation


Disconnect-ExchangeOnline -Confirm:$false


## ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

GETTING USERS SETTINGS ... password / MFA / etc 

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

Get-MsolUser -all | select DisplayName,UserPrincipalName,@{N= "MFAStatus"; E ={if( $_.StrongAuthenticationRequirements.State -ne $null) {$_.StrongAuthenticationRequirements.State} else {"Disabled" }}} | where MFAStatus -eq "Disabled"  | Export-Csv -Path "C:\Path\To\Save\UserInboxRules.csv" -NoTypeInformation  



If you encounter execution policy restrictions, you might need to set an appropriate execution policy, like Set-ExecutionPolicy RemoteSigned, or run the script with the policy temporarily bypassed using:
	powershell -ExecutionPolicy Bypass -File ".\CheckUsersWithoutMFA.ps1".



-withOutMFAOnly

Get-MFAStatus.ps1 -withOutMFAOnly