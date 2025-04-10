# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"

# Define the properties we want to retrieve (added department)
$properties = @(
    "id",
    "displayName",
    "userPrincipalName",
    "accountEnabled",
    "assignedLicenses",
    "department"
)

# Get all users with specified properties
$users = Get-MgUser -All -Property $properties |
    Where-Object {
        # Filter for accounts that are enabled and have at least one license
        $_.AccountEnabled -eq $true -and
        $_.AssignedLicenses.Count -gt 0
    }

# Create a custom output object and display results (added department)
$results = $users | ForEach-Object {
    [PSCustomObject]@{
        DisplayName       = $_.DisplayName
        UserPrincipalName = $_.UserPrincipalName
        Department        = $_.Department
        LicenseCount      = $_.AssignedLicenses.Count
        AccountEnabled    = $_.AccountEnabled
    }
}

# Display the results
#$results | Format-Table -AutoSize

$results | Export-Csv -Path "ActiveLicensedUsers.csv" -NoTypeInformation
# Optional: Export to CSV
# $results | Export-Csv -Path "ActiveLicensedUsers.csv" -NoTypeInformation

# Disconnect from Microsoft Graph
Disconnect-MgGraph