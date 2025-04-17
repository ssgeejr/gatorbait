Import-Module Microsoft.Graph

Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All", "AppRoleAssignment.Read.All", "DelegatedPermissionGrant.Read.All", "Application.Read.All"

$grants = Get-MgOauth2PermissionGrant -Filter "principalId eq 'sgee@wmmc.com'" -All

    foreach ($grant in $grants) {
        # Get service principal info
        $sp = Get-MgServicePrincipal -ServicePrincipalId $grant.ClientId

        $results += [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            AppName           = $sp.DisplayName
            AppId             = $sp.AppId
            ScopesGranted     = $grant.Scope
            ConsentType       = $grant.ConsentType
        }
    }

$results | Format-Table -AutoSize

Write-Host "`nScan complete. Review results for untrusted or high-scope applications." -ForegroundColor Green