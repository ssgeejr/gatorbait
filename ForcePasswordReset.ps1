# Import the Active Directory module
Import-Module ActiveDirectory

# Define the CSV input path and log file
$csvPath = "ActiveLicensedUsers.csv"
$logFile = "ForcePasswordReset.log"

# Function to write log entries
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -Append -FilePath $logFile
}

# Start processing
Write-Log "=== Starting ForcePasswordReset Script ==="

# Import the CSV file
try {
    $users = Import-Csv -Path $csvPath
    Write-Log "Imported $($users.Count) user(s) from $csvPath"
}
catch {
    Write-Log "ERROR: Failed to read the CSV file. $_"
    exit 1
}

# Process each user
foreach ($user in $users) {
    # Extract the username part before '@'
    $upn = $user.UserPrincipalName
    $username = $upn.Split("@")[0]

    try {
        # Step 1: Unset ChangePasswordAtLogon
        Set-ADUser -Identity $username -ChangePasswordAtLogon $false
        Write-Log "[$username] ChangePasswordAtLogon set to FALSE"

        # Step 2: Set ChangePasswordAtLogon
        Set-ADUser -Identity $username -ChangePasswordAtLogon $true
        Write-Log "[$username] ChangePasswordAtLogon set to TRUE"
    }
    catch {
        Write-Log "ERROR: Failed to update user $username. $_"
    }
}

Write-Log "=== Completed ForcePasswordReset Script ==="
