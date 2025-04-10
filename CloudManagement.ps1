# Define log file path
$logFile = "cloudManagement.log"

# Function to log errors
function Log-Error {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - ERROR: $Message" | Out-File -FilePath $logFile -Append
}

# Connect to Microsoft Graph with required scopes
try {
    Connect-MgGraph -Scopes "User.Read.All", "Directory.ReadWrite.All", "UserAuthenticationMethod.ReadWrite.All", "Policy.ReadWrite.AuthenticationMethod" -ErrorAction Stop
    Write-Host "Connected to Microsoft Graph successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to connect to Microsoft Graph: $_" -ForegroundColor Red
    Log-Error -Message "Failed to connect to Microsoft Graph: $_"
    exit
}

# Import the CSV file
try {
    $users = Import-Csv -Path "ActiveLicensedUsers.csv" -ErrorAction Stop
    Write-Host "Imported CSV successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to import CSV: $_" -ForegroundColor Red
    Log-Error -Message "Failed to import CSV: $_"
    Disconnect-MgGraph
    exit
}

foreach ($user in $users) {
    $userId = $user.UserPrincipalName

    Write-Host "Processing user: $userId" -ForegroundColor Cyan

    # 1. Revoke all active sessions
    try {
        Revoke-MgUserSignInSession -UserId $userId -ErrorAction Stop
        Write-Host "  - Sessions revoked successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "  - Failed to revoke sessions: $_" -ForegroundColor Red
        Log-Error -Message "User: $userId - Failed to revoke sessions: $_"
    }

    # 2. Enable per-user MFA
    try {
        $mfaBody = @{
            "perUserMfaState" = "enabled"
        }
        Invoke-MgGraphRequest -Method PATCH -Uri "/beta/users/$userId/authentication/requirements" -Body $mfaBody -ErrorAction Stop
        Write-Host "  - MFA enabled successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "  - Failed to enable MFA: $_" -ForegroundColor Red
        Log-Error -Message "User: $userId - Failed to enable MFA: $_"
    }
}

# Disconnect from Microsoft Graph
try {
    Disconnect-MgGraph -ErrorAction Stop
    Write-Host "Disconnected from Microsoft Graph" -ForegroundColor Green
}
catch {
    Write-Host "Failed to disconnect from Microsoft Graph: $_" -ForegroundColor Red
    Log-Error -Message "Failed to disconnect from Microsoft Graph: $_"
}

Write-Host "Script completed. Check $logFile for any errors." -ForegroundColor Green