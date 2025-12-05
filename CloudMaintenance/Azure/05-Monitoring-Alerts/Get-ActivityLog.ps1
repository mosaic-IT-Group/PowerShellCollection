#Requires -Modules Az.Accounts, Az.Monitor
<#
.SYNOPSIS
    Retrieves Azure Activity Log entries.
.DESCRIPTION
    Filters activity logs by time range, resource, or operation type.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [int]$Hours = 24,
    [string]$ResourceGroupName,
    [ValidateSet('All', 'Write', 'Delete', 'Action')]
    [string]$OperationType = 'All',
    [ValidateSet('All', 'Succeeded', 'Failed')]
    [string]$Status = 'All',
    [switch]$ExportCsv,
    [string]$ExportPath = ".\ActivityLog.csv"
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

$EndTime = Get-Date
$StartTime = $EndTime.AddHours(-$Hours)

Write-Host "Retrieving Activity Log (last $Hours hours)..." -ForegroundColor Cyan

$Params = @{
    StartTime = $StartTime
    EndTime = $EndTime
}

if ($ResourceGroupName) {
    $Params.ResourceGroupName = $ResourceGroupName
}

$Logs = Get-AzActivityLog @Params -ErrorAction SilentlyContinue

if (-not $Logs) {
    Write-Host "No activity log entries found."
    exit
}

# Filter by operation type
if ($OperationType -ne 'All') {
    $Logs = $Logs | Where-Object { $_.OperationName.Value -like "*$OperationType*" }
}

# Filter by status
if ($Status -ne 'All') {
    $Logs = $Logs | Where-Object { $_.Status.Value -eq $Status }
}

$Results = $Logs | Select-Object @{N='Timestamp';E={$_.EventTimestamp}},
    @{N='Operation';E={$_.OperationName.LocalizedValue}},
    @{N='Resource';E={$_.ResourceId.Split('/')[-1]}},
    @{N='ResourceGroup';E={$_.ResourceGroupName}},
    @{N='Status';E={$_.Status.Value}},
    @{N='Caller';E={$_.Caller}},
    @{N='Level';E={$_.Level}}

Write-Host "`n=== Activity Log ===" -ForegroundColor Green
Write-Host "Total entries: $($Results.Count)"

# Summary by status
$Results | Group-Object Status | ForEach-Object {
    $Color = switch ($_.Name) {
        'Succeeded' { 'Green' }
        'Failed' { 'Red' }
        default { 'Yellow' }
    }
    Write-Host "$($_.Name): $($_.Count)" -ForegroundColor $Color
}

Write-Host ""
$Results | Select-Object -First 50 | Format-Table Timestamp, Operation, Resource, Status, Caller -AutoSize

if ($Results.Count -gt 50) {
    Write-Host "... showing first 50 of $($Results.Count) entries"
}

if ($ExportCsv) {
    $Results | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "`nExported to: $ExportPath"
}
