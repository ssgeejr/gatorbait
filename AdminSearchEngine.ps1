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
$otherAdminsFile = "O365AdminsReport.csv"
$errorLogFile = "AdminReportsErrorLog.txt"

# Initialize arrays to store results and errors
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

# Get all other admin roles (excluding Domain Admins)
$otherAdminRoles = $roles | Where-Object { $_.DisplayName -like "*Admin*" }

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