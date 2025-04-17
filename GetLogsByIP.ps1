# Install the Microsoft Graph Sign-ins module if not already installed
# Install-Module Microsoft.Graph.Identity.Signins

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "AuditLog.Read.All"

# $ipAddress = "107.116.253.29"
#$ipAddress = "67.209.233.72"
$ipAddress = "2600:387:15:710::5"
$signInEvents = Get-MgAuditLogSignIn -Filter "ipAddress eq '$ipAddress'"

if ($signInEvents) {
    foreach ($event in $signInEvents) {
        Write-Host "Time: $($event.CreatedDateTime)"
        Write-Host "User: $($event.UserPrincipalName)"
        Write-Host "App: $($event.AppDisplayName)"
        Write-Host "IP Address: $($event.IpAddress)"
        Write-Host "Status: $($event.Status.errorCode)"
        Write-Host "---------------------"
    }
} else {
    Write-Host "No sign-in events found for IP address $ipAddress in Azure AD"
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph