# Import only necessary modules
Import-Module Microsoft.Graph.Authentication -Force
Import-Module Microsoft.Graph.Users -Force
Import-Module Microsoft.Graph.Identity.SignIns -Force

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All", "AuditLog.Read.All", "UserAuthenticationMethod.Read.All"  -Verbose

# Define the date boundaries
$minDays = (Get-Date).AddDays(-90)   # 90 days ago
$maxDays = (Get-Date).AddDays(-180)  # 180 days ago
$currentDate = Get-Date              # Today’s date for days calculation

Write-Host "MIN DAYS: " $minDays
Write-Host "MAX DAYS: " $maxDays

# Get today’s date in MMddyyyy format for filenames
$dateString = $currentDate.ToString("MMddyyyy")
Write-Host "-------------------------------------------------"
Write-Host "*** Starting Users Login > 90 AND < 180 Report ***"

# First call: Users inactive between 90 and 180 days (only enabled accounts)
$inactiveUsers90to180 = Get-MgUser -All -Property DisplayName, UserPrincipalName, Department, AssignedLicenses, SignInActivity, AccountEnabled | Where-Object {
    ($_.AssignedLicenses.Count -gt 0) -and
    ($_.AccountEnabled -eq $true) -and
    ($_.SignInActivity.LastSignInDateTime -lt $minDays) -and
    ($_.SignInActivity.LastSignInDateTime -ge $maxDays)
} | Select-Object DisplayName,
                  UserPrincipalName,
                  Department,
                  @{Name="LastLoginDateTime";Expression={$_.SignInActivity.LastSignInDateTime}},
                  @{Name="DaysSinceLastLogin";Expression={[math]::Floor(($currentDate - $_.SignInActivity.LastSignInDateTime).TotalDays)}}

# Export to CSV for 30-180 days with date in filename
$inactiveUsers90to180 | Export-Csv -Path "InactiveLicensedUsers_90to180_$dateString.csv" -NoTypeInformation
Write-Host "USER LOGIN > 30 AND < 180 DAYS WRITTEN TO: InactiveLicensedUsers_30to180_$dateString.csv"

Write-Host "-------------------------------------------------"
Write-Host "*** Starting Users Login > 180 Report ***"
# Second call: Users inactive greater than 180 days (only enabled accounts)
$inactiveUsers180plus = Get-MgUser -All -Property DisplayName, UserPrincipalName, Department, AssignedLicenses, SignInActivity, AccountEnabled | Where-Object {
    ($_.AssignedLicenses.Count -gt 0) -and
    ($_.AccountEnabled -eq $true) -and
    (($_.SignInActivity.LastSignInDateTime -lt $maxDays) -or ($_.SignInActivity.LastSignInDateTime -eq $null))
} | Select-Object DisplayName,
                  UserPrincipalName,
                  Department,
                  @{Name="LastLoginDateTime";Expression={$_.SignInActivity.LastSignInDateTime}},
                  @{Name="DaysSinceLastLogin";Expression={
                      if ($_.SignInActivity.LastSignInDateTime) {
                          [math]::Floor(($currentDate - $_.SignInActivity.LastSignInDateTime).TotalDays)
                      } else {
                          "Never"
                      }
                  }}

# Export to CSV for 180+ days with date in filename
$inactiveUsers180plus | Export-Csv -Path "InactiveLicensedUsers_180plus_$dateString.csv" -NoTypeInformation
Write-Host "USER LOGIN > 180 DAYS WRITTEN TO: InactiveLicensedUsers_180plus_$dateString.csv"

Write-Host "-------------------------------------------------"

#Write-Host "s: " $s
Write-Host "*** Starting MFA Violations Report ***"
# Get today’s date in MMddyyyy format for filename
$currentDate = Get-Date
$dateString = $currentDate.ToString("MMddyyyy")
Write-Host "ACTIVE MFA DATE: " $dateString


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

Write-Host "ACTIVE MFA VIOLATED REPORT SAVED TO: ActiveLicensedUsers_NoMFA_$dateString.csv"


Write-Host "-------------------------------------------------"
Write-Host "... report completed disconnecting from Graph ..."
# Disconnect
Disconnect-MgGraph