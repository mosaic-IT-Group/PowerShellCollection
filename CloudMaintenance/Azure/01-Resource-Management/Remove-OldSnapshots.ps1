#Requires -Modules Az.Accounts, Az.Compute
<#
.SYNOPSIS
    Removes old disk snapshots.
.DESCRIPTION
    Identifies and removes snapshots older than specified retention period.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$SubscriptionId,
    [int]$RetentionDays = 30,
    [string]$ResourceGroupName,
    [switch]$Force
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

$CutoffDate = (Get-Date).AddDays(-$RetentionDays)

Write-Host "Finding snapshots older than $RetentionDays days (before $($CutoffDate.ToString('yyyy-MM-dd')))..." -ForegroundColor Cyan

$Params = @{}
if ($ResourceGroupName) {
    $Params.ResourceGroupName = $ResourceGroupName
}

$Snapshots = Get-AzSnapshot @Params | Where-Object { $_.TimeCreated -lt $CutoffDate }

if ($Snapshots.Count -eq 0) {
    Write-Host "No old snapshots found."
    exit
}

Write-Host "`nFound $($Snapshots.Count) old snapshots:"
$Snapshots | Select-Object Name, ResourceGroupName, DiskSizeGB, TimeCreated | Format-Table -AutoSize

$TotalSize = ($Snapshots | Measure-Object -Property DiskSizeGB -Sum).Sum
Write-Host "Total size: $TotalSize GB (estimated monthly cost: ~$([math]::Round($TotalSize * 0.05, 2)))"

if (-not $Force) {
    $Confirm = Read-Host "`nDelete these snapshots? (y/n)"
    if ($Confirm -ne 'y') {
        Write-Host "Cancelled."
        exit
    }
}

foreach ($Snapshot in $Snapshots) {
    if ($PSCmdlet.ShouldProcess($Snapshot.Name, "Remove snapshot")) {
        Write-Host "Removing: $($Snapshot.Name)..." -NoNewline
        Remove-AzSnapshot -ResourceGroupName $Snapshot.ResourceGroupName -SnapshotName $Snapshot.Name -Force | Out-Null
        Write-Host " Done" -ForegroundColor Green
    }
}

Write-Host "`nCleanup complete."
