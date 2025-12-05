#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Reports on failed login attempts.
.DESCRIPTION
    Analyzes Security event log for failed login attempts and identifies patterns.
#>

[CmdletBinding()]
param(
    [int]$Hours = 24,
    [int]$AlertThreshold = 10,
    [string]$ExportPath
)

$StartTime = (Get-Date).AddHours(-$Hours)

Write-Host "Analyzing failed login attempts (last $Hours hours)...`n"

$FailedLogins = Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    Id = 4625
    StartTime = $StartTime
} -ErrorAction SilentlyContinue

if (-not $FailedLogins) {
    Write-Host "No failed login attempts found."
    exit
}

# Parse event data
$ParsedEvents = foreach ($Event in $FailedLogins) {
    $Xml = [xml]$Event.ToXml()
    $Data = $Xml.Event.EventData.Data

    [PSCustomObject]@{
        TimeCreated = $Event.TimeCreated
        TargetUserName = ($Data | Where-Object { $_.Name -eq 'TargetUserName' }).'#text'
        TargetDomainName = ($Data | Where-Object { $_.Name -eq 'TargetDomainName' }).'#text'
        IpAddress = ($Data | Where-Object { $_.Name -eq 'IpAddress' }).'#text'
        WorkstationName = ($Data | Where-Object { $_.Name -eq 'WorkstationName' }).'#text'
        FailureReason = ($Data | Where-Object { $_.Name -eq 'Status' }).'#text'
    }
}

Write-Host "Total failed attempts: $($ParsedEvents.Count)"

# Group by username
Write-Host "`nFailed Attempts by User:"
$ByUser = $ParsedEvents | Group-Object TargetUserName | Sort-Object Count -Descending | Select-Object -First 10
$ByUser | Format-Table Name, Count -AutoSize

# Group by IP
Write-Host "Failed Attempts by IP Address:"
$ByIP = $ParsedEvents | Group-Object IpAddress | Sort-Object Count -Descending | Select-Object -First 10
$ByIP | Format-Table Name, Count -AutoSize

# Alert on potential brute force
$BruteForceIPs = $ByIP | Where-Object { $_.Count -ge $AlertThreshold }
if ($BruteForceIPs) {
    Write-Warning "Potential brute force detected from:"
    $BruteForceIPs | ForEach-Object { Write-Warning "  $($_.Name): $($_.Count) attempts" }
}

if ($ExportPath) {
    $ParsedEvents | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "`nExported to: $ExportPath"
}
