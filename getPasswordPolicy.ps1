#Connect-MsolService
Get-MsolUser -All | Where-Object { $_.IsLicensed -eq $true } | Select-Object UserPrincipalName, PasswordNeverExpires | Export-Csv -Path "activePasswordPolicty.csv" -NoTypeInformation



