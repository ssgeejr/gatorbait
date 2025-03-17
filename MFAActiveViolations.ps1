
# Import necessary modules
Import-Module Microsoft.Graph.Authentication -Force
Import-Module Microsoft.Graph.Users -Force
Import-Module Microsoft.Graph.Identity.SignIns -Force

# Connect to Microsoft Graph with required scopes
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All", "UserAuthenticationMethod.Read.All" -Verbose

# Get today’s date in MMddyyyy format for filename
$currentDate = Get-Date
$dateString = $currentDate.ToString("MMddyyyy")

# Get all active, licensed users
$activeLicensedUsers = Get-MgUser -All -Property DisplayName, UserPrincipalName, Department, AssignedLicenses, AccountEnabled | Where-Object {
    ($_.AssignedLicenses.Count -gt 0) -and
    ($_.AccountEnabled -eq $true)
}

# Initialize an array to store users without MFA
$usersWithoutMfa = @()

# Check each user’s authentication methods
foreach ($user in $activeLicensedUsers) {
    # Get authentication methods for the user
    $authMethods = Get-MgUserAuthenticationMethod -UserId $user.UserPrincipalName

    # Check if any MFA-capable methods are registered (e.g., Phone, FIDO2, Authenticator)
    $mfaRegistered = $authMethods | Where-Object {
        $_.AdditionalProperties["@odata.type"] -in @(
            "#microsoft.graph.phoneAuthenticationMethod",
            "#microsoft.graph.fido2AuthenticationMethod",
            "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod",
            "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod"
        )
    }

    # If no MFA methods are registered, add the user to the list
    if (-not $mfaRegistered) {
        $usersWithoutMfa += [PSCustomObject]@{
            DisplayName       = $user.DisplayName
            UserPrincipalName = $user.UserPrincipalName
            Department        = $user.Department
        }
    }
}

# Export to CSV
$usersWithoutMfa | Export-Csv -Path "ActiveLicensedUsers_NoMFA_$dateString.csv" -NoTypeInformation

# Disconnect
Disconnect-MgGraph