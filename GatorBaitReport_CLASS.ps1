
using namespace System.Data
using namespace MySql.Data.MySqlClient

# Import MySQL .NET assembly BEFORE defining the class
$libPath = Join-Path -Path $PSScriptRoot -ChildPath "lib\MySql.Data.dll"
if (-Not ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.Location -eq $libPath })) {
    Write-Host "[DEBUG] Importing MySQL library from $libPath"
    Add-Type -Path $libPath
}

class ReportEngine {
    [string]$ConfigPath
    [hashtable]$Config
    [MySql.Data.MySqlClient.MySqlConnection]$Connection

    ReportEngine() {
        Write-Host "[DEBUG] Initializing ReportEngine class"
        $this.ConfigPath = Join-Path $HOME ".gatorbait\gatorbait.cfg"
        $this.LoadConfig()
        $this.OpenConnection()
    }

    [void] LoadConfig() {
        Write-Host "[DEBUG] Loading config from $($this.ConfigPath)"
        if (-Not (Test-Path $this.ConfigPath)) {
            throw "Configuration file not found at $($this.ConfigPath)"
        }
        $json = Get-Content $this.ConfigPath -Raw | ConvertFrom-Json
        $this.Config = @{
            Host     = $json.host
            User     = $json.user
            Password = $json.passwd
            Database = $json.db
        }
        Write-Host "[DEBUG] Configuration loaded: $($this.Config | Out-String)"
    }

    [void] OpenConnection() {
        $connStr = "server={0};user={1};password={2};database={3}" -f `
            $this.Config.Host, $this.Config.User, $this.Config.Password, $this.Config.Database
        $this.Connection = [MySqlConnection]::new($connStr)
        $this.Connection.Open()
        Write-Host "[DEBUG] MySQL connection opened"
    }

    [datetime] GetMaxRunDate() {
        Write-Host "[DEBUG] Getting max run_date"
        $query = "SELECT MAX(run_date) AS max_run_date FROM compliance_audit_log"
        $cmd = $this.Connection.CreateCommand()
        $cmd.CommandText = $query
        $reader = $cmd.ExecuteReader()
        $maxDate = $null
        if ($reader.Read()) {
            $maxDate = $reader["max_run_date"]
        }
        $reader.Close()
        Write-Host "[DEBUG] Max run_date: $maxDate"
        return [datetime]::Parse($maxDate)
    }

    [System.Data.DataTable] QueryByType([int]$type, [datetime]$date) {
        $query = @"
SELECT name, email, department, lastlogin, numdays 
FROM compliance_audit_log 
WHERE type = @runType AND run_date = @runDate 
ORDER BY name ASC
"@
        $cmd = $this.Connection.CreateCommand()
        $cmd.CommandText = $query

        $runType = $cmd.Parameters.Add("@runType", 3)
        $runType.Value = $type

        $runDate = $cmd.Parameters.Add("@runDate", 253)
        $runDate.Value = $date

        $adapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($cmd)
        $table = New-Object System.Data.DataTable
        $adapter.Fill($table) | Out-Null
        return $table
    }

    [hashtable] GetReportTitles() {
        $cmd = $this.Connection.CreateCommand()
        $cmd.CommandText = "SELECT `key`, `value` FROM xref ORDER BY `key` ASC"
        $reader = $cmd.ExecuteReader()
        $titles = @{}
        while ($reader.Read()) {
            $titles[$reader["key"]] = $reader["value"]
        }
        $reader.Close()
        return $titles
    }

    [void] PrintTable([string]$title, [System.Data.DataTable]$table, [int]$type) {
        Write-Host "`n**$title**"
        if ($type -eq 0) {
            Write-Host "|-Name-------------|-Email---------------------|-Department----------|"
            Write-Host "|------------------|---------------------------|----------------------|"
            foreach ($row in $table.Rows) {
                "{0,-18}|{1,-27}|{2,-22}" -f $row.name, $row.email, $row.department
            }
        } else {
            Write-Host "|-Name-------------|-Email---------------------|-Department----------|-Last Login--------|-Num Days--|"
            Write-Host "|------------------|---------------------------|----------------------|-------------------|-----------|"
            foreach ($row in $table.Rows) {
                "{0,-18}|{1,-27}|{2,-22}|{3,-19}|{4,-11}" -f $row.name, $row.email, $row.department, $row.lastlogin, $row.numdays
            }
        }
    }

    [void] Run() {
        $maxDate = $this.GetMaxRunDate()
        $titles = $this.GetReportTitles()
        foreach ($key in $titles.Keys) {
            $table = $this.QueryByType($key, $maxDate)
            $this.PrintTable($titles[$key], $table, $key)
        }
        $this.Connection.Close()
        Write-Host "[DEBUG] Report complete and connection closed."
    }
}

# Allow standalone or external usage
if ($MyInvocation.InvocationName -eq ".\GatorBaitReport.ps1") {
    try {
        $report = [ReportEngine]::new()
        $report.Run()
    } catch {
        Write-Error $_
    }
}
