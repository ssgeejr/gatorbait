Connect-MsolService


#Connect-MsolService -Credential $credential

#$credential = Import-CliXml -Path "C:\Users\geest\.gatorbait\gatorbait.api"


# Define the date 180 days ago
$inactiveDate = (Get-Date).AddDays(-30)

# Get all users and filter based on last logon
#Get-MsolUser -All | Where-Object { 
#    ($_.LastLogonTimestamp -lt $inactiveDate) -or ($_.LastLogonTimestamp -eq $null)
#} | Select-Object UserPrincipalName, LastLogonTimestamp

Get-MsolUser -All | Where-Object { 
    (($_.LastLogonTimestamp -lt $inactiveDate) -or ($_.LastLogonTimestamp -eq $null)) -and 
    ($_.IsLicensed -eq $true)
} | Select-Object FirstName, LastName, UserPrincipalName, Department, @{Name="Licenses";Expression={$_.Licenses.AccountSkuId}} | Export-Csv -Path "30day_InactiveUsers_Details.csv" -NoTypeInformation

