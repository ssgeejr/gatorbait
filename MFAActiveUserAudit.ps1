
# Import necessary modules
Import-Module Microsoft.Graph.Authentication -Force
Import-Module Microsoft.Graph.Users -Force
Import-Module Microsoft.Graph.Identity.SignIns -Force


# Connect to Microsoft Graph with required scopes
Connect-MgGraph -Scopes "User.Read.All", "UserAuthenticationMethod.Read.All" -NoWelcome


# Get today’s date in MMddyyyy format for filename
$currentDate = Get-Date
$dateString = $currentDate.ToString("MMddyyyy")

# Get all active users with their license details and authentication methods
$users = Get-MgUser -All -Property "Id", "DisplayName", "UserPrincipalName", "AccountEnabled", "AssignedLicenses" `
    | Where-Object { $_.AccountEnabled -eq $true -and $_.AssignedLicenses.Count -gt 0 }

# Initialize an array to store results
$results = [System.Collections.Generic.List[Object]]::new()

# Loop through each user to check MFA status
foreach ($user in $users) {
    # Get the user's authentication methods
    $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id

    # Check if MFA is enabled (look for methods beyond just password)
    $mfaEnabled = $false
    foreach ($method in $authMethods) {
        if ($method.AdditionalProperties["@odata.type"] -ne "#microsoft.graph.passwordAuthenticationMethod") {
            $mfaEnabled = $true
            break
        }
    }

    # If MFA is not enabled, add the user to the results
    if (-not $mfaEnabled) {
        $userInfo = [PSCustomObject]@{
            DisplayName       = $user.DisplayName
            UserPrincipalName = $user.UserPrincipalName
            AccountEnabled    = $user.AccountEnabled
            LicenseCount      = $user.AssignedLicenses.Count
        }
        $results.Add($userInfo)
    }
}

# Export the results to a CSV file
#$exportPath = "C:\Temp\ActiveLicensedUsersNoMFA.csv"
#$results | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

# Export to CSV
$results | Export-Csv -Path "ActiveLicensedUsers_NoMFA_$dateString.csv" -NoTypeInformation

# Output completion message
#Write-Host "Report generated successfully. Results exported to $exportPath"
#Write-Host "Total users found: $($results.Count)"