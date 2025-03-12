# Import only necessary modules
Import-Module Microsoft.Graph.Authentication -Force
Import-Module Microsoft.Graph.Users -Force

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All", "AuditLog.Read.All" -NoWelcome

# Define the date boundaries
$minDays = (Get-Date).AddDays(-30)   # 30 days ago
$maxDays = (Get-Date).AddDays(-180)  # 180 days ago
$currentDate = Get-Date              # Today’s date for days calculation

# First call: Users inactive between 30 and 180 days
$inactiveUsers30to180 = Get-MgUser -All -Property DisplayName, UserPrincipalName, Department, AssignedLicenses, SignInActivity | Where-Object {
    ($_.AssignedLicenses.Count -gt 0) -and
    ($_.SignInActivity.LastSignInDateTime -lt $minDays) -and
    ($_.SignInActivity.LastSignInDateTime -ge $maxDays)
} | Select-Object DisplayName,
                  UserPrincipalName,
                  Department,
                  @{Name="LastLoginDateTime";Expression={$_.SignInActivity.LastSignInDateTime.ToString("MM/dd/yyyy HH:mm")}},
                  @{Name="DaysSinceLastLogin";Expression={[math]::Floor(($currentDate - $_.SignInActivity.LastSignInDateTime).TotalDays)}}

# Display results for 30-180 days
#Write-Host "Users inactive between 30 and 180 days:"
#$inactiveUsers30to180

# Export to CSV for 30-180 days
$inactiveUsers30to180 | Export-Csv -Path "InactiveLicensedUsers_30to180_MgGraph.csv" -NoTypeInformation

# Second call: Users inactive greater than 180 days
$inactiveUsers180plus = Get-MgUser -All -Property DisplayName, UserPrincipalName, Department, AssignedLicenses, SignInActivity | Where-Object {
    ($_.AssignedLicenses.Count -gt 0) -and
    (($_.SignInActivity.LastSignInDateTime -lt $maxDays) -or ($_.SignInActivity.LastSignInDateTime -eq $null))
} | Select-Object DisplayName,
                  UserPrincipalName,
                  Department,
                  @{Name="LastLoginDateTime";Expression={if ($_.SignInActivity.LastSignInDateTime) { $_.SignInActivity.LastSignInDateTime.ToString("MM/dd/yyyy HH:mm") } else { "" }}},
                  @{Name="DaysSinceLastLogin";Expression={
                      if ($_.SignInActivity.LastSignInDateTime) {
                          [math]::Floor(($currentDate - $_.SignInActivity.LastSignInDateTime).TotalDays)
                      } else {
                          "Never"
                      }
                  }}

# Display results for 180+ days
#Write-Host "`nUsers inactive greater than 180 days:"
#$inactiveUsers180plus

# Export to CSV for 180+ days
$inactiveUsers180plus | Export-Csv -Path "InactiveLicensedUsers_180plus_MgGraph.csv" -NoTypeInformation

# Disconnect
Disconnect-MgGraph