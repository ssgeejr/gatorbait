Add-Type -Path (Join-Path $PSScriptRoot "lib\MySql.Data.dll")
# Load configuration from ~/.gatorbait/gatorbait.cfg
function Get-GatorbaitConfig {
    Write-Host "[DEBUG] Entering Get-GatorbaitConfig"
    $configPath = Join-Path $HOME ".gatorbait\gatorbait.cfg"
    if (-Not (Test-Path $configPath)) {
        throw "Configuration file not found at $configPath"
    }
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    Write-Host "[DEBUG] Loaded configuration from $configPath"
    return $config
}

# Initialize logger
function Write-GatorLog {
    param(
        [string]$Message
    )
    $logDir = Join-Path $PSScriptRoot "log"
    if (-not (Test-Path $logDir)) {
        Write-Host "[DEBUG] Creating log directory at $logDir"
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }
    $logPath = Join-Path $logDir "gatorbait.log"
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$timestamp - $Message" | Out-File -FilePath $logPath -Append -Encoding UTF8
    Write-Host "[DEBUG] Logged message: $Message"
}

# Open MySQL connection
function Open-MySqlConnection {
    param(
        [object]$config
    )
    Write-Host "[DEBUG] Entering Open-MySqlConnection"
    if (-not ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq 'MySql.Data' })) {
        try {
            Write-Host "[DEBUG] Attempting to load MySql.Data assembly"
            Add-Type -AssemblyName "MySql.Data"
        } catch {
            throw "MySql.Data assembly not found. Please install the MySQL .NET Connector and ensure it's in the GAC or referenced by name."
        }
    }

    $connStr = "server={0};user={1};password={2};database={3};SslMode=None" -f `
        $config.mysql.host, $config.mysql.user, $config.mysql.passwd, $config.mysql.db

    $conn = New-Object MySql.Data.MySqlClient.MySqlConnection($connStr)
    $conn.Open()
    Write-Host "[DEBUG] MySQL connection opened successfully"
    return $conn
}

# Insert a record into compliance_audit_log
function Insert-ComplianceRecord {
    param(
        [object]$conn,
        [object]$user,
        [int]$type
    )
    Write-Host "[DEBUG] Inserting record for: $($user.DisplayName) (type $type)"
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = @"
        INSERT INTO compliance_audit_log
        (name, email, department, lastlogin, numdays, type)
        VALUES
        (@name, @email, @department, @lastlogin, @numdays, @type);
"@

    $cmd.Parameters.Add("@name", 253).Value = $user.DisplayName
    $cmd.Parameters.Add("@email", 253).Value = $user.UserPrincipalName
    $cmd.Parameters.Add("@department", 253).Value = $user.Department

    if ($type -eq 0) {
        $cmd.Parameters.Add("@lastlogin", 12).Value = [DBNull]::Value
        $cmd.Parameters.Add("@numdays", 3).Value = [DBNull]::Value
    } else {
        if ($user.SignInActivity.LastSignInDateTime) {
            $lastLogin = [datetime]::Parse($user.SignInActivity.LastSignInDateTime)
            $cmd.Parameters.Add("@lastlogin", 12).Value = $lastLogin
            $days = ([datetime]::Now - $lastLogin).Days
            $cmd.Parameters.Add("@numdays", 3).Value = $days
        } else {
            $cmd.Parameters.Add("@lastlogin", 12).Value = [DBNull]::Value
            $cmd.Parameters.Add("@numdays", 3).Value = [DBNull]::Value
        }
    }

    $cmd.Parameters.Add("@type", 1).Value = $type
    $cmd.ExecuteNonQuery() | Out-Null
    Write-Host "[DEBUG] Insert successful"
}

# Main routine
function Run-GatorbaitReport {
    Write-Host "[DEBUG] Starting Run-GatorbaitReport"
    Import-Module Microsoft.Graph.Authentication -Force
    Import-Module Microsoft.Graph.Users -Force
    Import-Module Microsoft.Graph.Identity.SignIns -Force
    Write-Host "[DEBUG] Modules imported successfully"

    Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All", "AuditLog.Read.All", "UserAuthenticationMethod.Read.All"
    Write-Host "[DEBUG] Connected to Microsoft Graph"

    $config = Get-GatorbaitConfig
    $conn = Open-MySqlConnection -config $config

    $minDays = (Get-Date).AddDays(-90)
    $maxDays = (Get-Date).AddDays(-180)
    $mfaInsertCount = 0
    try {
        Write-Host "[DEBUG] Pulling 90–180 day inactive users"
        $users90to180 = Get-MgUser -All -Property DisplayName, UserPrincipalName, Department, SignInActivity, AssignedLicenses, AccountEnabled | Where-Object {
            ($_.AssignedLicenses.Count -gt 0) -and ($_.AccountEnabled -eq $true) -and
            ($_.SignInActivity.LastSignInDateTime -lt $minDays) -and
            ($_.SignInActivity.LastSignInDateTime -ge $maxDays)
        }
        $users90to180 | ForEach-Object { Insert-ComplianceRecord -conn $conn -user $_ -type 1 }
        Write-GatorLog "Inserted $($users90to180.Count) users (90–180 days)"

        Write-Host "[DEBUG] Pulling 180+ day inactive users"
        $users180plus = Get-MgUser -All -Property DisplayName, UserPrincipalName, Department, SignInActivity, AssignedLicenses, AccountEnabled | Where-Object {
            ($_.AssignedLicenses.Count -gt 0) -and ($_.AccountEnabled -eq $true) -and
            ($_.SignInActivity.LastSignInDateTime -lt $maxDays)
        }
        $users180plus | ForEach-Object { Insert-ComplianceRecord -conn $conn -user $_ -type 2 }
        Write-GatorLog "Inserted $($users180plus.Count) users (180+ days)"

        Write-Host "[DEBUG] Pulling MFA non-compliant users"

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
                $mfaUser = [PSCustomObject]@{
                    DisplayName       = $user.DisplayName
                    UserPrincipalName = $user.UserPrincipalName
                    Department        = $user.Department
                }
                Insert-ComplianceRecord -conn $conn -user $mfaUser -type 0
                $mfaInsertCount++
            }
        }


#        $mfaUsers = Get-MgUserAuthenticationMethod -UserId "*" | Where-Object { $_.Methods.Count -eq 0 }
#        foreach ($user in $mfaUsers) {
#            $mfaUser = Get-MgUser -UserId $user.Id -Property DisplayName, UserPrincipalName, Department
#            Insert-ComplianceRecord -conn $conn -user $mfaUser -type 0
#        }
#        Write-GatorLog "Inserted $($mfaUsers.Count) users (MFA non-compliant)"
        Write-GatorLog "Inserted $mfaInsertCount users (MFA non-compliant)"

        Write-GatorLog "Run completed successfully."
        Write-Host "[DEBUG] Run-GatorbaitReport finished"
    } catch {
        Write-GatorLog "ERROR: $($_.Exception.Message)"
        Write-Host "[DEBUG] Exception occurred: $($_.Exception.Message)"
        throw $_
    } finally {
        $conn.Close()
        Write-Host "[DEBUG] MySQL connection closed"
    }
}

Run-GatorbaitReport
