# Install Microsoft.Graph module if not already installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Installing Microsoft.Graph module..."
    Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}

# Import required Microsoft Graph modules
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Identity.DirectoryManagement

# Connect to Microsoft Graph with necessary permissions
try {
    Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All", "RoleManagement.Read.Directory" -ErrorAction Stop
    Write-Host "Connected to Microsoft Graph successfully."
}
catch {
    Write-Error "Failed to connect to Microsoft Graph. Error: $_"
    exit
}

# Output file paths
$domainAdminFile = "DomainAdminsReport.csv"
$otherAdminsFile = "OtherAdminsReport.csv"
$errorLogFile = "AdminReportsErrorLog.txt"

# Initialize arrays to store results and errors
$domainAdmins = @()
$otherAdmins = @()
$errorLog = @()

# Get all directory roles
try {
    $roles = Get-MgDirectoryRole -All -ErrorAction Stop
    Write-Host "Retrieved $($roles.Count) directory roles."
}
catch {
    Write-Error "Failed to retrieve directory roles. Error: $_"
    $errorLog += "Failed to retrieve directory roles: $_"
    Disconnect-MgGraph
    $errorLog | Out-File -FilePath $errorLogFile
    exit
}

# Get Domain Admins (specifically the 'Domain Admins' role)
$domainAdminRole = $roles | Where-Object { $_.DisplayName -eq "Domain Admins" }

if ($domainAdminRole) {
    try {
        $domainAdminMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $domainAdminRole.Id -ErrorAction Stop
        foreach ($member in $domainAdminMembers) {
            try {
                $user = Get-MgUser -UserId $member.Id -Property DisplayName, GivenName, Surname, Mail -ErrorAction Stop
                $domainAdmins += [PSCustomObject]@{
                    FirstName = $user.GivenName
                    LastName  = $user.Surname
                    Email     = $user.Mail
                    Role      = $domainAdminRole.DisplayName
                }
            }
            catch {
                $errorMsg = "Failed to retrieve user $($member.Id) for Domain Admins. Error: $_"
                Write-Warning $errorMsg
                $errorLog += $errorMsg
            }
        }
    }
    catch {
        $errorMsg = "Failed to retrieve Domain Admins members. Error: $_"
        Write-Error $errorMsg
        $errorLog += $errorMsg
    }
}
else {
    Write-Warning "No 'Domain Admins' role found."
    $errorLog += "No 'Domain Admins' role found."
}

# Get all other admin roles (excluding Domain Admins)
$otherAdminRoles = $roles | Where-Object { $_.DisplayName -ne "Domain Admins" -and $_.DisplayName -like "*Admin*" }

foreach ($role in $otherAdminRoles) {
    try {
        $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -ErrorAction Stop
        Write-Host "Processing role: $($role.DisplayName) with $($members.Count) members."
        foreach ($member in $members) {
            try {
                $user = Get-MgUser -UserId $member.Id -Property DisplayName, GivenName, Surname, Mail -ErrorAction Stop
                $otherAdmins += [PSCustomObject]@{
                    FirstName = $user.GivenName
                    LastName  = $user.Surname
                    Email     = $user.Mail
                    Role      = $role.DisplayName
                }
            }
            catch {
                $errorMsg = "Failed to retrieve user $($member.Id) for role '$($role.DisplayName)'. Error: $_"
                Write-Warning $errorMsg
                $errorLog += $errorMsg
            }
        }
    }
    catch {
        $errorMsg = "Failed to retrieve members for role '$($role.DisplayName)'. Error: $_"
        Write-Error $errorMsg
        $errorLog += $errorMsg
    }
}

# Export reports to CSV
try {
    $domainAdmins | Export-Csv -Path $domainAdminFile -NoTypeInformation -ErrorAction Stop
    Write-Host "Domain Admins report exported to $domainAdminFile"
}
catch {
    Write-Error "Failed to export Domain Admins report. Error: $_"
    $errorLog += "Failed to export Domain Admins report: $_"
}

try {
    $otherAdmins | Export-Csv -Path $otherAdminsFile -NoTypeInformation -ErrorAction Stop
    Write-Host "Other Admins report exported to $otherAdminsFile"
}
catch {
    Write-Error "Failed to export Other Admins report. Error: $_"
    $errorLog += "Failed to export Other Admins report: $_"
}

# Export error log
if ($errorLog) {
    $errorLog | Out-File -FilePath $errorLogFile
    Write-Host "Errors logged to $errorLogFile"
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
Write-Host "Disconnected from Microsoft Graph."