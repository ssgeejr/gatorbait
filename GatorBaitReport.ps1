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

function fetchReportDetails
{
    param(
        [object]$conn
    )
    Write-Host "[DEBUG] Fetching Max Date"
    # Get max run_date
    $maxCmd = $conn.CreateCommand()
    $maxCmd.CommandText = "SELECT DATE(MAX(run_date)) FROM compliance_audit_log"
    $maxDate = $maxCmd.ExecuteScalar()
    Write-Host "[DEBUG] Max run_date: $maxDate"
    Write-Host "[DEBUG] Pulling Report Title [0]"
    $maxCmd.CommandText = "SELECT XREF.value from XREF where XREF.key = 0"
    $rptTitle = $maxCmd.ExecuteScalar()
    Write-Host "[DEBUG] Report Title: $rptTitle"

    $maxCmd.CommandText = "SELECT name, email, department, lastlogin, numdays FROM compliance_audit_log WHERE DATE(run_date) = @runDate AND type = @reportType"
    $maxCmd.Parameters.Add("@runDate", 12).Value = $maxDate
    $maxCmd.Parameters.Add("@reportType", 3).Value = 0


    Write-Host "[DEBUG] Final SQL Command: $($maxCmd.CommandText)"
    Write-Host "[DEBUG] Run Date Bound: $runDate"
    Write-Host "[DEBUG] Report Type: $type"

    Write-Host $maxCmd.CommandText

    $reader = $maxCmd.ExecuteReader()


    Write-Host ""
    Write-Host "** $($rptTitle) **"
    Write-Host ("|{0,-32}|{1,-32}|{2,-32}|" -f "Name", "Email", "Department")
    Write-Host "|--------------------------------|--------------------------------|--------------------------------|"

    while ($reader.Read()) {
        $name = $reader["name"]
        $email = $reader["email"]
        $dept = if ($reader["department"]) { $reader["department"] } else { "" }

        Write-Host ("|{0,-32}|{1,-32}|{2,-32}|" -f $name, $email, $dept)

        #Write-Host "$name __ $email __ $dept"
    }
    Write-Host "|--------------------------------|--------------------------------|--------------------------------|"
    $reader.Close()
    Write-Host "`n"
}

function Report
{
    $config = Get-GatorbaitConfig
    $conn = Open-MySqlConnection -config $config
    fetchReportDetails($conn)



}
Report
