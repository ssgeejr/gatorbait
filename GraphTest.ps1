# Ensure Microsoft.Graph module is installed (Uncomment the line below if needed)
# Install-Module Microsoft.Graph -Scope CurrentUser -Force

# Import Microsoft Graph Module
Import-Module Microsoft.Graph

# Connect to Microsoft Graph with necessary permissions
Connect-MgGraph -Scopes "User.Read.All", "AuditLog.Read.All", "Directory.Read.All"

# Define cutoff date (180 days ago)
$CutoffDate = (Get-Date).AddDays(-180)

# Get all users with sign-in activity and filter inactive users
$InactiveUsers = Get-MgUser -All -Property DisplayName, UserPrincipalName, SignInActivity |
    Where-Object { $_.SignInActivity.LastSignInDateTime -lt $CutoffDate -or $_.SignInActivity.LastSignInDateTime -eq $null } |
    Select-Object DisplayName, UserPrincipalName, @{Name="LastSignIn";Expression={$_.SignInActivity.LastSignInDateTime}}

# Display results in table format
$InactiveUsers | Format-Table -AutoSize

# Export results to a CSV file (Optional)
$InactiveUsers | Export-Csv -Path "180days_InactiveUsers.csv" -NoTypeInformation
# Display results
# $InactiveUsers | Format-Table -AutoSize

# Disconnect from Microsoft Graph (Optional)
Disconnect-MgGraph



