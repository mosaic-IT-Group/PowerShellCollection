<#
.SYNOPSIS
    Checks health status of critical Windows services.
.DESCRIPTION
    Monitors specified services and reports any that are not running.
#>

[CmdletBinding()]
param(
    [string[]]$Services = @(
        'wuauserv',      # Windows Update
        'BITS',          # Background Intelligent Transfer
        'Spooler',       # Print Spooler
        'W32Time',       # Windows Time
        'EventLog',      # Windows Event Log
        'Schedule',      # Task Scheduler
        'WinDefend',     # Windows Defender
        'Dhcp',          # DHCP Client
        'Dnscache'       # DNS Client
    ),
    [switch]$AutoRestart
)

$Results = foreach ($ServiceName in $Services) {
    $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if (-not $Service) {
        [PSCustomObject]@{
            Name = $ServiceName
            DisplayName = 'Not Found'
            Status = 'Missing'
            StartType = 'N/A'
        }
        continue
    }

    $Status = $Service.Status

    if ($AutoRestart -and $Status -ne 'Running' -and $Service.StartType -ne 'Disabled') {
        Write-Host "Attempting to start: $($Service.DisplayName)..."
        try {
            Start-Service -Name $ServiceName -ErrorAction Stop
            $Status = 'Restarted'
        }
        catch {
            $Status = "Failed: $_"
        }
    }

    [PSCustomObject]@{
        Name = $ServiceName
        DisplayName = $Service.DisplayName
        Status = $Status
        StartType = $Service.StartType
    }
}

Write-Host "`nService Health Report:"
$Results | Format-Table -AutoSize

$StoppedCount = ($Results | Where-Object { $_.Status -notin @('Running', 'Restarted') }).Count
if ($StoppedCount -gt 0) {
    Write-Warning "$StoppedCount service(s) are not running!"
}
