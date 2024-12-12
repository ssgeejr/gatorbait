# Connect to MS Online Service
#Connect-MsolService

# Get all users who are licensed and do NOT have MFA enabled
$licensedUsersWithoutMFA = Get-MsolUser -All | 
    Where-Object { $_.IsLicensed -eq $true -and $_.StrongAuthenticationRequirements.Count -eq 0 }

# Select relevant fields to display along with explicit MFA status and Last Password Changed Timestamp
$selectedUserInfo = $licensedUsersWithoutMFA | 
    Select-Object DisplayName, UserPrincipalName, IsLicensed,
        @{Name="MFAEnabled";Expression={"Not Enabled"}}, 
        LastPasswordChangeTimeStamp

# Display the results
$selectedUserInfo | Format-Table -AutoSize

# Optionally, export to CSV
$selectedUserInfo | Export-Csv -Path "non-compliance_MFA.csv" -NoTypeInformation
