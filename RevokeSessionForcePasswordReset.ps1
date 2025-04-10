# Start logging verbose output to a file
$VerbosePreference = "Continue"
Start-Transcript -Path "GraphVerboseLog.txt"

# Connect to Microsoft Graph with required scopes
Connect-MgGraph -Scopes "User.Read.All", "Directory.ReadWrite.All", "User.ReadWrite.All", "UserAuthenticationMethod.ReadWrite.All", "Policy.ReadWrite.AuthenticationMethod"

# Import the CSV file
$users = Import-Csv -Path "ActiveLicensedUsers.csv"

foreach ($user in $users) {
    $userId = $user.UserPrincipalName

    Write-Host "Processing user: $userId" -ForegroundColor Cyan

    # Check if user is synced from on-premises
    $isSynced = (Get-MgUser -UserId $userId -Property OnPremisesSyncEnabled).OnPremisesSyncEnabled
    Write-Host "  - Sync status: OnPremisesSyncEnabled = $isSynced" -ForegroundColor Cyan

    # 1. Revoke all active sessions
    try {
        Revoke-MgUserSignInSession -UserId $userId -ErrorAction Stop -Verbose
        Write-Host "  - Sessions revoked successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "  - Failed to revoke sessions: $_" -ForegroundColor Red
    }

    # 2. Force password reset based on sync status
    if ($isSynced -eq $true) {
        # On-premises synced user
        Write-Host "  - Warning: User is synced from on-premises. Password reset must be done in Active Directory." -ForegroundColor Yellow
        Write-Host "  - Suggestion: Use 'Set-ADUser -Identity $userId -ChangePasswordAtLogon `$true' on your AD server." -ForegroundColor Yellow
    }
    else {
        # Cloud-only user
        try {
            $body = @{
                "passwordProfile" = @{
                    "forceChangePasswordNextSignIn" = $true
                }
            }
            Invoke-MgGraphRequest -Method PATCH -Uri "/v1.0/users/$userId" -Body $body -ErrorAction Stop -Verbose
            Write-Host "  - Password reset command sent successfully" -ForegroundColor Green

            # Wait and verify
            Start-Sleep -Seconds 5
            $updatedUser = Get-MgUser -UserId $userId -Property passwordProfile
            if ($updatedUser.PasswordProfile.ForceChangePasswordNextSignIn -eq $true) {
                Write-Host "  - Verified: Password reset is enforced" -ForegroundColor Green
            } else {
                Write-Host "  - Warning: Password reset not enforced after delay!" -ForegroundColor Yellow
                Write-Host "  - Current state: $($updatedUser.PasswordProfile | ConvertTo-Json)" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "  - Failed to force password reset: $_" -ForegroundColor Red
        }
    }

    # 3. Enable per-user MFA
    try {
        $mfaBody = @{
            "perUserMfaState" = "enabled"
        }
        Invoke-MgGraphRequest -Method PATCH -Uri "/beta/users/$userId/authentication/requirements" -Body $mfaBody -ErrorAction Stop
        Write-Host "  - MFA enabled successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "  - Failed to enable MFA: $_" -ForegroundColor Red
    }
}

# Disconnect from Microsoft Graph and stop logging
Disconnect-MgGraph
Stop-Transcript