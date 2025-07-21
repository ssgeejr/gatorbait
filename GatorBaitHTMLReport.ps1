
Add-Type -Path (Join-Path $PSScriptRoot "lib\\MySql.Data.dll")

$htmlBuilder = [System.Text.StringBuilder]::new()

function Append-Html {
    param ([string]$content)
    [void]$htmlBuilder.AppendLine($content)
}

function Write-HtmlReport {
    $outputPath = Join-Path $PSScriptRoot "weekly_report.html"
    [System.IO.File]::WriteAllText($outputPath, $htmlBuilder.ToString())
    Write-Host "✅ HTML report written to $outputPath"
}

function Start-HtmlDocument {
    Append-Html "<html><head><style>
        body { font-family: Arial, sans-serif; font-size: 14px; color: #333; margin: 20px; }
        h2, h3 { color: #2a2a2a; }
        table { border-collapse: collapse; width: 900px; margin-top: 10px; table-layout: fixed; }
        th, td { border: 1px solid #ccc; padding: 8px; text-align: left; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }
        th { background-color: #f2f2f2; }
    </style></head><body>"
}

function End-HtmlDocument {
    Append-Html "</body></html>"
}

function Append-HeaderSection {
    param ($titles, $deltas)
    Append-Html "<h2>Cybersecurity Report – $(Get-Date -Format 'MMMM dd, yyyy')</h2>"
    Append-Html "<h3>📊 Summary</h3><ul>"
    foreach ($key in $titles.Keys) {
        $delta = $deltas[$key]
        Append-Html "<li>[$($delta.curr)] $($titles[$key]) – Delta: (+$($delta.curr - $delta.prev))</li>"
    }
    Append-Html "</ul>"
}

function Append-TableSection {
    param ($title, $rows)
    $includeLogin = $title -like "*90 Days*" -or $title -like "*180 Days*"
    Append-Html "<h3>$title</h3><table><colgroup>
        <col style='width: 300px;' /><col style='width: 300px;' /><col style='width: 300px;' />"
    if ($includeLogin) {
        Append-Html "<col style='width: 100px;' /><col style='width: 100px;' />"
    }
    Append-Html "</colgroup><thead><tr><th>Name</th><th>Email</th><th>Department</th>"
    if ($includeLogin) {
        Append-Html "<th>Last Login</th><th>#Days</th>"
    }
    Append-Html "</tr></thead><tbody>"

    foreach ($row in $rows) {
        $name = if ($row.name.Length -gt 28) { $row.name.Substring(0,28) } else { $row.name }
        $email = if ($row.email.Length -gt 32) { $row.email.Substring(0,32) } else { $row.email }
        $dept = if ($row.department.Length -gt 32) { $row.department.Substring(0,32) } else { $row.department }
        if ($includeLogin) {
            $login = if ($row.lastlogin -and $row.lastlogin -ne [DBNull]::Value) { ([datetime]$row.lastlogin).ToString("MM/dd/yy") } else { "" }
            $days = $row.numdays
            Append-Html ("<tr><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td></tr>" -f $name, $email, $dept, $login, $days)
        } else {
            Append-Html ("<tr><td>{0}</td><td>{1}</td><td>{2}</td></tr>" -f $name, $email, $dept)
        }
    }
    Append-Html "</tbody></table>"
}

function Get-GatorbaitConfig {
    $configPath = Join-Path $HOME ".gatorbait\\gatorbait.cfg"
    if (-Not (Test-Path $configPath)) {
        throw "Configuration file not found at $configPath"
    }
    return Get-Content $configPath -Raw | ConvertFrom-Json
}

function Open-MySqlConnection {
    param([object]$config)
    $connStr = "server={0};user={1};password={2};database={3};SslMode=None" -f `
        $config.mysql.host, $config.mysql.user, $config.mysql.passwd, $config.mysql.db
    $conn = New-Object MySql.Data.MySqlClient.MySqlConnection($connStr)
    $conn.Open()
    return $conn
}

function Get-ReportTitles {
    param($conn)
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "SELECT XREF.key, XREF.value FROM XREF ORDER BY XREF.key"
    $reader = $cmd.ExecuteReader()
    $titles = @{}
    while ($reader.Read()) {
        $titles[$reader.GetInt32(0)] = $reader.GetString(1)
    }
    $reader.Close()
    return $titles
}

function Get-DeltaCounts {
    param($conn)
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "SELECT DISTINCT DATE(run_date) AS run_date FROM compliance_audit_log ORDER BY run_date DESC LIMIT 2"
    $reader = $cmd.ExecuteReader()
    $dates = @()
    while ($reader.Read()) {
        $dates += [datetime]$reader["run_date"]
    }
    $reader.Close()

    if ($dates.Count -lt 2) {
        throw "Not enough historical data to generate delta comparison"
    }

    $currDate, $prevDate = $dates[0], $dates[1]
    $deltas = @{}
    foreach ($type in 0..2) {
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = @"
SELECT 
  (SELECT COUNT(*) FROM compliance_audit_log WHERE DATE(run_date) = @currDate AND type = @type) AS curr,
  (SELECT COUNT(*) FROM compliance_audit_log WHERE DATE(run_date) = @prevDate AND type = @type) AS prev
"@
        $cmd.Parameters.Add("@currDate", [MySql.Data.MySqlClient.MySqlDbType]::Date).Value = $currDate
        $cmd.Parameters.Add("@prevDate", [MySql.Data.MySqlClient.MySqlDbType]::Date).Value = $prevDate
        $cmd.Parameters.Add("@type", [MySql.Data.MySqlClient.MySqlDbType]::Int32).Value = $type

        $reader = $cmd.ExecuteReader()
        if ($reader.Read()) {
            $deltas[$type] = @{ curr = $reader["curr"]; prev = $reader["prev"] }
        }
        $reader.Close()
    }
    return $deltas
}

function Get-ReportRows {
    param($conn, $type)
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "SELECT DATE(MAX(run_date)) FROM compliance_audit_log"
    $runDate = $cmd.ExecuteScalar()

    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "SELECT name, email, department, lastlogin, numdays FROM compliance_audit_log WHERE DATE(run_date) = @runDate AND type = @type"
    $cmd.Parameters.Add("@runDate", [MySql.Data.MySqlClient.MySqlDbType]::Date).Value = $runDate
    $cmd.Parameters.Add("@type", [MySql.Data.MySqlClient.MySqlDbType]::Int32).Value = $type

    $reader = $cmd.ExecuteReader()
    $rows = @()
    while ($reader.Read()) {
        $rows += [PSCustomObject]@{
            name       = $reader["name"]
            email      = $reader["email"]
            department = $reader["department"]
            lastlogin  = $reader["lastlogin"]
            numdays    = $reader["numdays"]
        }
    }
    $reader.Close()
    return $rows
}

# ----------- MAIN EXECUTION --------------
$config = Get-GatorbaitConfig
$conn = Open-MySqlConnection -config $config

Start-HtmlDocument

$titles = Get-ReportTitles -conn $conn
$deltas = Get-DeltaCounts -conn $conn

Append-HeaderSection -titles $titles -deltas $deltas

foreach ($type in 0..2) {
    $rows = Get-ReportRows -conn $conn -type $type
    Append-TableSection -title $titles[$type] -rows $rows
}

End-HtmlDocument
Write-HtmlReport

$conn.Close()
