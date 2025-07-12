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


## Install Powershell on Debian 

sudo apt install -y wget apt-transport-https software-properties-common
wget -q https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y powershell dos2unix

sudo apt install dos2unix
dos2unix GatorBait.ps1 GatorBaitReport.ps1 GatorBaitInit.ps1

Test with pwsh


To always stay current with PowerShell 7+, use the Snap package (optional):
`sudo snap install powershell --classic`
That gives you the latest stable release, managed by Snap updates.



You're missing the **Microsoft Graph SDK modules**, which aren't included by default in PowerShell — and your script expects at least these three:

* `Microsoft.Graph.Authentication`
* `Microsoft.Graph.Users`
* `Microsoft.Graph.Identity.SignIns`

And it's failing because:

* The **modules aren’t installed**, and
* Therefore, `Connect-MgGraph` (which is part of `Microsoft.Graph.Authentication`) isn't available.

---

## ✅ Fix: Install Microsoft Graph SDK Modules (AllUsers Scope)

Run the following as root or with `sudo`:

```bash
sudo pwsh -Command 'Install-Module Microsoft.Graph -Scope AllUsers -Force'
```

> This will install the **entire Graph SDK**, including submodules like `Users`, `Authentication`, `Identity.SignIns`, etc.

If you prefer to install only the required modules individually (faster, lighter), use:

```bash
sudo pwsh -Command 'Install-Module Microsoft.Graph.Authentication -Scope AllUsers -Force'
sudo pwsh -Command 'Install-Module Microsoft.Graph.Users -Scope AllUsers -Force'
sudo pwsh -Command 'Install-Module Microsoft.Graph.Identity.SignIns -Scope AllUsers -Force'
```

---

## ✅ After Install

You can verify the modules are globally available:

```bash
pwsh -Command 'Get-Module -ListAvailable Microsoft.Graph.*'
```

And test `Connect-MgGraph` manually:

```bash
pwsh
> Import-Module Microsoft.Graph.Authentication
> Connect-MgGraph -Scopes "User.Read.All"
```

---

### 🔐 Optional: Suppress Trust Prompt

If you see this during install:

```
Untrusted repository. You are installing the modules from an untrusted repository.
```

You can permanently trust the PowerShell Gallery:

```bash
sudo pwsh -Command 'Set-PSRepository -Name PSGallery -InstallationPolicy Trusted'
```

---



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