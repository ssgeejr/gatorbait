
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-Module AzureAD

Install-Module -Name AzureAD -Scope CurrentUser -AllowClobber -Force

Connect-AzureAD

Get-AzureADUser -SearchString "jane.doe@yourdomain.com"


Issues to resolve: Access has been blocked by Conditional Access policies. The access policy does not allow token issuance.


Failure reason
The provided grant has expired due to it being revoked, a fresh auth token is needed. The user might have changed or reset their password. The grant was issued on '{authTime}' and the TokensValidFrom date (before which tokens are not valid) for this user is '{validDate}'.