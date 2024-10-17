Get-MsolUser -All | 
    Where-Object {$_.IsLicensed -eq $true} |  # Filter for users where IsLicensed is true
    Select-Object UserPrincipalName, DisplayName, LastPasswordChangeTimeStamp, IsLicensed | 
    Export-Csv -Path "LicensedUsersReport.csv" -NoTypeInformation