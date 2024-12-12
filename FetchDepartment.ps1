# Connect to MsolService
Write-Output "Connecting to Microsoft Online Service..."
Connect-MsolService

# Define the CSV file path
$csvFilePath = "withOutMFAOnly_12122024.csv"

# Check if the file exists
if (!(Test-Path $csvFilePath)) {
    Write-Output "Error: CSV file not found at $csvFilePath."
    exit
}

# Read the CSV file
$csvData = Import-Csv -Path $csvFilePath

# Process each row
foreach ($row in $csvData) {
    $primaryKey = $row.UserPrincipalName

    if ($primaryKey) {
        # Get user details
        $user = Get-MsolUser -UserPrincipalName $primaryKey | Select-Object UserPrincipalName, DisplayName, Department
        if ($user) {
            Write-Output $user
        } else {
            Write-Output "No data found for $primaryKey."
        }
    }
}
