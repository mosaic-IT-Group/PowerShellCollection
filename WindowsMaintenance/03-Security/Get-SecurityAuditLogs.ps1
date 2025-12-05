#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Reviews security audit logs for suspicious activity.
.DESCRIPTION
    Analyzes Windows Security event logs for failed logins, privilege escalation, etc.
#>

[CmdletBinding()]
param(
    [int]$Hours = 24,
    [string]$ExportPath
)

$StartTime = (Get-Date).AddHours(-$Hours)

# Failed login attempts (Event ID 4625)
$FailedLogins = Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    Id = 4625
    StartTime = $StartTime
} -ErrorAction SilentlyContinue

# Successful logins (Event ID 4624)
$SuccessfulLogins = Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    Id = 4624
    StartTime = $StartTime
} -ErrorAction SilentlyContinue

# Privilege escalation (Event ID 4672)
$PrivilegeUse = Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    Id = 4672
    StartTime = $StartTime
} -ErrorAction SilentlyContinue

$Report = [PSCustomObject]@{
    TimeRange = "$Hours hours"
    FailedLogins = $FailedLogins.Count
    SuccessfulLogins = $SuccessfulLogins.Count
    PrivilegeEscalations = $PrivilegeUse.Count
}

Write-Host "`nSecurity Audit Summary (Last $Hours hours):"
Write-Host "  Failed Logins: $($FailedLogins.Count)"
Write-Host "  Successful Logins: $($SuccessfulLogins.Count)"
Write-Host "  Privilege Escalations: $($PrivilegeUse.Count)"

if ($FailedLogins.Count -gt 10) {
    Write-Warning "High number of failed login attempts detected!"
}

if ($ExportPath) {
    $Report | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "`nReport exported to: $ExportPath"
}
