<#
.SYNOPSIS
    Generates and sends a comprehensive maintenance report.
.DESCRIPTION
    Collects system health data and sends an email summary.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SmtpServer,

    [Parameter(Mandatory)]
    [string]$To,

    [string]$From = "maintenance@$env:USERDNSDOMAIN",

    [string]$Subject = "System Maintenance Report - $(Get-Date -Format 'yyyy-MM-dd')"
)

$ReportDate = Get-Date -Format "yyyy-MM-dd HH:mm"
$ComputerName = $env:COMPUTERNAME

# Gather data
$OS = Get-CimInstance Win32_OperatingSystem
$Uptime = (Get-Date) - $OS.LastBootUpTime

$Disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    "$($_.DeviceID) $([math]::Round($_.FreeSpace/1GB, 2)) GB free of $([math]::Round($_.Size/1GB, 2)) GB"
}

$Services = Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' }
$StoppedServices = if ($Services) { $Services.DisplayName -join "`n" } else { "All automatic services running" }

$RecentErrors = Get-WinEvent -FilterHashtable @{
    LogName = 'System', 'Application'
    Level = 2
    StartTime = (Get-Date).AddHours(-24)
} -MaxEvents 10 -ErrorAction SilentlyContinue

$ErrorSummary = if ($RecentErrors) {
    $RecentErrors | ForEach-Object { "$($_.TimeCreated): $($_.Message.Substring(0, [Math]::Min(100, $_.Message.Length)))..." }
} else {
    "No errors in the last 24 hours"
}

# Build report
$Body = @"
SYSTEM MAINTENANCE REPORT
========================
Generated: $ReportDate
Computer: $ComputerName

SYSTEM STATUS
-------------
OS: $($OS.Caption)
Uptime: $($Uptime.Days) days, $($Uptime.Hours) hours

DISK SPACE
----------
$($Disks -join "`n")

SERVICES
--------
$StoppedServices

RECENT ERRORS (Last 24h)
------------------------
$($ErrorSummary -join "`n")
"@

# Send email
try {
    Send-MailMessage -SmtpServer $SmtpServer -From $From -To $To -Subject $Subject -Body $Body
    Write-Host "Report sent to: $To"
}
catch {
    Write-Error "Failed to send email: $_"
    Write-Host $Body
}
