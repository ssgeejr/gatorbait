# Connect to MS Online Service
Connect-MsolService

# Get all users, filter for those who have a license and MFA not enabled
$usersWithoutMFA = Get-MsolUser -All | 
    Where-Object { $_.IsLicensed -eq $true -and $_.StrongAuthenticationRequirements.Count -eq 0 }

# Display the results
$usersWithoutMFA | Select-Object UserPrincipalName, DisplayName, IsLicensed | Format-Table -AutoSize

# Optionally, export to CSV
# $usersWithoutMFA | Select-Object UserPrincipalName, DisplayName, IsLicensed | Export-Csv -Path "UsersWithoutMFA.csv" -NoTypeInformation
