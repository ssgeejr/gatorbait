# Define log file path
$logFile = "checkADPasswordError.log"

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
    Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All" -ErrorAction Stop
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

    # Check if user is managed by on-premises AD for password resets
    try {
        $isSynced = (Get-MgUser -UserId $userId -Property OnPremisesSyncEnabled -ErrorAction Stop).OnPremisesSyncEnabled
        if ($isSynced -eq $true) {
            Write-Host "  - Password reset is managed by on-premises Active Directory" -ForegroundColor Yellow
        }
        else {
            Write-Host "  - Password reset is managed in the cloud (Azure AD)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  - Failed to check AD sync status: $_" -ForegroundColor Red
        Log-Error -Message "User: $userId - Failed to check AD sync status: $_"
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