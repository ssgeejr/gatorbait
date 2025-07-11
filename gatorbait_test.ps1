# pwreporting.ps1
param (
    [ValidateSet("--pw", "--mfa")]
    [string]$ReportType
)

function PrintTime {
    param (
        [string]$type
    )
    switch ($type) {
        "noarg" { Write-Output "No arguments date: $(Get-Date)" }
        "pw" { Write-Output "Password reporting date: $(Get-Date)" }
        "mfa" { Write-Output "MFA reporting date: $(Get-Date)" }
    }
}

function GetUsersWithoutMFA {
    Get-MsolUser -All |
        Where-Object { $_.IsLicensed -eq $true -and $_.StrongAuthenticationRequirements.Count -eq 0 } |
        Select-Object UserPrincipalName, DisplayName, LastPasswordChangeTimeStamp, IsLicensed |
        Export-Csv -Path "LicensedUsersReport.csv" -NoTypeInformation
    Write-Output "MFA reporting completed. Data exported to LicensedUsersReport.csv."
}

if (-not $ReportType) {
    Write-Output "No arguments provided."
    PrintTime -type "noarg"
} elseif ($ReportType -eq "--pw") {
    Write-Output "Password reporting selected."
    PrintTime -type "pw"
} elseif ($ReportType -eq "--mfa") {
    Write-Output "MFA reporting selected."
    PrintTime -type "mfa"
    GetUsersWithoutMFA
}
