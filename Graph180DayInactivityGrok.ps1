# Import only necessary modules
Import-Module Microsoft.Graph.Authentication -Force
Import-Module Microsoft.Graph.Users -Force

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All", "AuditLog.Read.All" -Verbose

# Define the date boundaries
$minDays = (Get-Date).AddDays(-30)   # 30 days ago
$maxDays = (Get-Date).AddDays(-180)  # 180 days ago
$currentDate = Get-Date              # Today’s date for days calculation

# Get today’s date in MMddyyyy format for filenames
$dateString = $currentDate.ToString("MMddyyyy")

# First call: Users inactive between 30 and 180 days (only enabled accounts)
$inactiveUsers30to180 = Get-MgUser -All -Property DisplayName, UserPrincipalName, Department, AssignedLicenses, SignInActivity, AccountEnabled | Where-Object {
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
$inactiveUsers30to180 | Export-Csv -Path "InactiveLicensedUsers_30to180_$dateString.csv" -NoTypeInformation

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

# Disconnect
Disconnect-MgGraph