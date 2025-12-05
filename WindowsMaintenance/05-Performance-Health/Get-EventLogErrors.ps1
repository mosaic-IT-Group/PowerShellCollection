<#
.SYNOPSIS
    Retrieves error events from Windows Event Logs.
.DESCRIPTION
    Scans System, Application, and Security logs for errors and warnings.
#>

[CmdletBinding()]
param(
    [int]$Hours = 24,
    [ValidateSet('Error', 'Warning', 'Both')]
    [string]$Level = 'Both'
)

$StartTime = (Get-Date).AddHours(-$Hours)
$Logs = @('System', 'Application')

$LevelFilter = switch ($Level) {
    'Error'   { @(2) }
    'Warning' { @(3) }
    'Both'    { @(2, 3) }
}

$Events = foreach ($LogName in $Logs) {
    Get-WinEvent -FilterHashtable @{
        LogName = $LogName
        Level = $LevelFilter
        StartTime = $StartTime
    } -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, LogName, LevelDisplayName, Id, ProviderName, Message
}

if ($Events) {
    Write-Host "Found $($Events.Count) events in the last $Hours hours:`n"

    $Events |
        Sort-Object TimeCreated -Descending |
        Format-Table TimeCreated, LogName, LevelDisplayName, Id, ProviderName -AutoSize

    # Summary by source
    Write-Host "`nTop Error Sources:"
    $Events |
        Group-Object ProviderName |
        Sort-Object Count -Descending |
        Select-Object -First 10 Name, Count |
        Format-Table -AutoSize
}
else {
    Write-Host "No errors or warnings found in the last $Hours hours."
}
