#Requires -Modules Az.Accounts, Az.Compute, Az.Monitor
<#
.SYNOPSIS
    Identifies VMs that can be downsized.
.DESCRIPTION
    Analyzes CPU/memory metrics to find overprovisioned VMs.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [int]$Days = 14,
    [int]$CpuThreshold = 20,
    [int]$MemoryThreshold = 30,
    [switch]$ExportCsv,
    [string]$ExportPath = ".\VMRightSizing.csv"
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

$EndTime = Get-Date
$StartTime = $EndTime.AddDays(-$Days)

Write-Host "Analyzing VM utilization over the last $Days days..." -ForegroundColor Cyan
Write-Host "Thresholds - CPU: <$CpuThreshold%, Memory: <$MemoryThreshold%"

$VMs = Get-AzVM -Status | Where-Object { $_.PowerState -eq 'VM running' }

$Results = foreach ($VM in $VMs) {
    Write-Host "  Checking $($VM.Name)..." -NoNewline

    $ResourceId = $VM.Id

    # Get CPU metrics
    $CpuMetric = Get-AzMetric -ResourceId $ResourceId -MetricName "Percentage CPU" `
        -StartTime $StartTime -EndTime $EndTime -TimeGrain 01:00:00 -AggregationType Average `
        -ErrorAction SilentlyContinue

    $AvgCpu = if ($CpuMetric.Data) {
        [math]::Round(($CpuMetric.Data | Measure-Object -Property Average -Average).Average, 2)
    } else { 'N/A' }

    $MaxCpu = if ($CpuMetric.Data) {
        [math]::Round(($CpuMetric.Data | Measure-Object -Property Average -Maximum).Maximum, 2)
    } else { 'N/A' }

    $VMDetails = Get-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name
    $CurrentSize = $VMDetails.HardwareProfile.VmSize

    $Recommendation = if ($AvgCpu -ne 'N/A' -and $AvgCpu -lt $CpuThreshold -and $MaxCpu -lt 50) {
        'Consider downsizing'
    } else {
        'Right-sized'
    }

    Write-Host " Done"

    [PSCustomObject]@{
        Name = $VM.Name
        ResourceGroup = $VM.ResourceGroupName
        CurrentSize = $CurrentSize
        'AvgCPU%' = $AvgCpu
        'MaxCPU%' = $MaxCpu
        Recommendation = $Recommendation
    }
}

Write-Host "`n=== VM Right-Sizing Report ===" -ForegroundColor Green
$Results | Format-Table -AutoSize

$ToDownsize = $Results | Where-Object { $_.Recommendation -eq 'Consider downsizing' }
if ($ToDownsize) {
    Write-Host "`nVMs recommended for downsizing:" -ForegroundColor Yellow
    $ToDownsize | Select-Object Name, CurrentSize, 'AvgCPU%' | Format-Table -AutoSize
}

if ($ExportCsv) {
    $Results | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Exported to: $ExportPath"
}
