# Complete documentation for lazyadmin https://lazyadmin.nl/powershell/list-office365-mfa-status-powershell/

#Download these two files
#	One is just a control script to enable the execution of powershell the other is the powershell script we're going to be using
Invoke-WebRequest -Uri https://raw.githubusercontent.com/ruudmens/LazyAdmin/refs/heads/master/Office365/MFAStatus.ps1 -OutFile MFAStatus.ps1
Invoke-WebRequest -Uri https://raw.githubusercontent.com/ssgeejr/gatorbait/refs/heads/main/pscontrol.cmd -OutFile pscontrol.cmd


#Install the MSOnline toolkit
Install-Module MSOnline -Force


#Open Powershell
#Allow powershell to run powershell scripts
.\pscontrol.cmd --unlock 

#get details for a single user
.\Get-MFAStatus.ps1 -UserPrincipalName 'johndoe@contoso.com'




#export those single user results to a csv files
.\Get-MFAStatus.ps1 -UserPrincipalName 'johndoe@contoso.com' | Export-CSV mfasearch.csv -noTypeInformation


#Get only the users without MFA
.\Get-MFAStatus.ps1 -withOutMFAOnly | Export-CSV withOutMFAOnly_112524.csv -noTypeInformation


#Get all valid users and their settings
.\Get-MFAStatus.ps1 | Export-CSV mfastatus.csv -noTypeInformation



#When you're done, lock powershell from running any ps1 scripts
.\pscontrol.cmd 



Get-MsolUser -all | select DisplayName,UserPrincipalName,@{N= "MFAStatus"; E ={if( $_.StrongAuthenticationRequirements.State -ne $null) {$_.StrongAuthenticationRequirements.State} else {"Disabled" }}} | where MFAStatus -eq "Disabled"  | Export-Csv -Path "azureMFA.csv" -NoTypeInformation  


