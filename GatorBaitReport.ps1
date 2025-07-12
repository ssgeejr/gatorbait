Add-Type -Path (Join-Path $PSScriptRoot "lib\MySql.Data.dll")
Add-Type -Path (Join-Path $PSScriptRoot "lib\PdfSharp.dll")

$global:reportBuilder = [System.Text.StringBuilder]::new()
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
        [object]$conn,
        [int]$type
    )
    Write-Host "[DEBUG] Fetching Max Date"
    # Get max run_date
    $maxCmd = $conn.CreateCommand()
    $maxCmd.CommandText = "SELECT DATE(MAX(run_date)) FROM compliance_audit_log"
    $maxDate = $maxCmd.ExecuteScalar()
    Write-Host "[DEBUG] Max run_date: $maxDate"
    Write-Host "[DEBUG] Pulling Report Title [0]"
    $maxCmd.CommandText = "SELECT XREF.value from XREF where XREF.key = $type"
    $rptTitle = $maxCmd.ExecuteScalar()
    Write-Host "[DEBUG] Report Title: $rptTitle"

    $maxCmd.CommandText = "SELECT name, email, department, lastlogin, numdays FROM compliance_audit_log WHERE DATE(run_date) = @runDate AND type = @reportType"
    $maxCmd.Parameters.Add("@runDate", 12).Value = $maxDate
    $maxCmd.Parameters.Add("@reportType", 3).Value = $type

    Write-Host "[DEBUG] Final SQL Command: $($maxCmd.CommandText)"
    Write-Host "[DEBUG] Run Date Bound: $runDate"
    Write-Host "[DEBUG] Report Type: $type"

    Write-Host $maxCmd.CommandText

    $reader = $maxCmd.ExecuteReader()

    Write-Host ""
    inlineWrite "** $($rptTitle) **"
    inlineWrite ("|{0,-32}|{1,-32}|{2,-32}|" -f "Name", "Email", "Department")
    inlineWrite "|--------------------------------|--------------------------------|--------------------------------|"

    while ($reader.Read()) {
        $name = $reader["name"]
        $email = $reader["email"]
        $dept = if ($reader["department"]) { $reader["department"] } else { "" }

        inlineWrite ("|{0,-32}|{1,-32}|{2,-32}|" -f $name, $email, $dept)

        #Write-Host "$name __ $email __ $dept"
    }
    inlineWrite "|--------------------------------|--------------------------------|--------------------------------|"

    $reader.Close()



#    Set-Content -Path "DBReport.txt" -Value $reportBuilder.ToString()
}

function generate-Header {
    param (
        [object]$conn
    )

    inlineWrite "Details:"

    # Step 1: Get the two most recent report dates
    $dateCmd = $conn.CreateCommand()
    $dateCmd.CommandText = "SELECT DISTINCT DATE(run_date) AS run_date FROM compliance_audit_log ORDER BY run_date DESC LIMIT 2"
    $reader = $dateCmd.ExecuteReader()

    $dateList = @()
    while ($reader.Read()) {
        $dateList += [datetime]$reader["run_date"]
    }
    $reader.Close()

    if ($dateList.Count -lt 2) {
        inlineWrite "[WARN] Not enough historical data for delta comparison."
        return
    }

    $currentDate = $dateList[0]
    $priorDate   = $dateList[1]

    Write-Host "[DEBUG] Current run_date: $currentDate"
    Write-Host "[DEBUG] Prior run_date:   $priorDate"

    # Step 2: Load report titles from XREF table
    $titles = @{}
    $xrefCmd = $conn.CreateCommand()
    $xrefCmd.CommandText = "SELECT XREF.key, XREF.value FROM XREF ORDER BY XREF.key"
    $reader = $xrefCmd.ExecuteReader()
    while ($reader.Read()) {
        $k = $reader.GetInt32(0)
        $v = $reader.GetString(1)
        $titles[$k] = $v
    }
    $reader.Close()

    # Step 3: Compare current and prior user counts for each report type
    foreach ($type in 0..2) {
        $sql = "SELECT " +
               "(SELECT COUNT(*) FROM compliance_audit_log WHERE DATE(run_date) = @currentDate AND type = @type) AS curr, " +
               "(SELECT COUNT(*) FROM compliance_audit_log WHERE DATE(run_date) = @priorDate AND type = @type) AS prev"

        $countCmd = $conn.CreateCommand()
        $countCmd.CommandText = $sql
        $countCmd.Parameters.Add("@currentDate", 12).Value = $currentDate
        $countCmd.Parameters.Add("@priorDate", 12).Value = $priorDate
        $countCmd.Parameters.Add("@type", 1).Value = $type

        $reader = $countCmd.ExecuteReader()
        if ($reader.Read()) {
            $curr = [int]$reader["curr"]
            $prev = [int]$reader["prev"]
            $delta = $curr - $prev
            $symbol = if ($delta -ge 0) { "+" } else { "" }
            $label = $titles[$type]
            inlineWrite "[$curr] $label - Prior week Delta (${symbol}${delta})"
        }
        $reader.Close()
    }
    inlineWrite " "
    inlineWrite " "
}



function inlineWrite {
    param (
        [Parameter(Mandatory=$true)]
        [string]$msg
    )
    Write-Host $msg
    [void]$global:reportBuilder.AppendLine($msg)
}

function Report
{
    $config = Get-GatorbaitConfig
    $conn = Open-MySqlConnection -config $config

    generate-Header -conn $conn

    foreach ($key in 0..2) {
        fetchReportDetails $conn $key
        inlineWrite " "
        inlineWrite " "
    }

    $today = Get-Date -Format "MMddyyyy"
    $filename = "${today}_Report.txt"
    Set-Content -Path $filename -Value $global:reportBuilder.ToString()
#    Set-Content -Path "MFA_Report.txt" -Value $global:reportBuilder.ToString()

    #TODO
    #Save report as a PDF, code broken in function Write-PdfReport ... in progress
    #Write-PdfReport -text $global:reportBuilder.ToString()

}

function Write-PdfReport {
    param (
        [string]$text,
        [string]$outputPath = "$PSScriptRoot\GatorBaitReport.pdf"
    )

    $doc = New-Object PdfSharp.Pdf.PdfDocument
    $doc.Info.Title = "GatorBait Compliance Report"

    $page = $doc.AddPage()
    $gfx = [PdfSharp.Drawing.XGraphics]::FromPdfPage($page)
    $font = New-Object PdfSharp.Drawing.XFont("Courier New", 10)

    # Split lines and render with line spacing
    $lines = $text -split "`n"
    $lineHeight = $font.GetHeight($gfx) + 2
    $y = 20

    foreach ($line in $lines) {
        if ($y + $lineHeight -gt $page.Height) {
            $page = $doc.AddPage()
            $gfx = [PdfSharp.Drawing.XGraphics]::FromPdfPage($page)
            $y = 20
        }
        $gfx.DrawString($line, $font, [PdfSharp.Drawing.XBrushes]::Black, 20, $y)
        $y += $lineHeight
    }

    $doc.Save($outputPath)
    Write-Host "[PDF] Report saved to: $outputPath"
}


Report
