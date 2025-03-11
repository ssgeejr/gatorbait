$credential = Get-Credential
$credential | Export-CliXml -Path "C:\Users\geest\.gatorbait\gatorbait.api"