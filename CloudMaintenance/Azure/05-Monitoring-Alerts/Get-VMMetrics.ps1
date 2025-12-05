#Requires -Modules Az.Accounts, Az.Compute, Az.Monitor
<#
.SYNOPSIS
    Retrieves performance metrics for Azure VMs.
.DESCRIPTION
    Gets CPU, memory, disk, and network metrics for specified VMs.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$ResourceGroupName,
    [string]$VMName,
    [int]$Hours = 24,
    [ValidateSet('Average', 'Maximum', 'Minimum')]
    [string]$Aggregation = 'Average'
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

$EndTime = Get-Date
$StartTime = $EndTime.AddHours(-$Hours)
$TimeGrain = '01:00:00'

Write-Host "Retrieving VM metrics for last $Hours hours..." -ForegroundColor Cyan

$Params = @{}
if ($ResourceGroupName) { $Params.ResourceGroupName = $ResourceGroupName }
if ($VMName) { $Params.Name = $VMName }

$VMs = Get-AzVM @Params

$Results = foreach ($VM in $VMs) {
    Write-Host "  Processing $($VM.Name)..."

    $ResourceId = $VM.Id

    # CPU
    $CpuMetric = Get-AzMetric -ResourceId $ResourceId -MetricName "Percentage CPU" `
        -StartTime $StartTime -EndTime $EndTime -TimeGrain $TimeGrain `
        -AggregationType $Aggregation -ErrorAction SilentlyContinue

    $Cpu = if ($CpuMetric.Data) {
        [math]::Round(($CpuMetric.Data | Measure-Object -Property $Aggregation -Average).Average, 2)
    } else { 'N/A' }

    # Network In
    $NetInMetric = Get-AzMetric -ResourceId $ResourceId -MetricName "Network In Total" `
        -StartTime $StartTime -EndTime $EndTime -TimeGrain $TimeGrain `
        -AggregationType Total -ErrorAction SilentlyContinue

    $NetIn = if ($NetInMetric.Data) {
        [math]::Round(($NetInMetric.Data | Measure-Object -Property Total -Sum).Sum / 1GB, 2)
    } else { 'N/A' }

    # Network Out
    $NetOutMetric = Get-AzMetric -ResourceId $ResourceId -MetricName "Network Out Total" `
        -StartTime $StartTime -EndTime $EndTime -TimeGrain $TimeGrain `
        -AggregationType Total -ErrorAction SilentlyContinue

    $NetOut = if ($NetOutMetric.Data) {
        [math]::Round(($NetOutMetric.Data | Measure-Object -Property Total -Sum).Sum / 1GB, 2)
    } else { 'N/A' }

    # Disk Operations
    $DiskReadMetric = Get-AzMetric -ResourceId $ResourceId -MetricName "Disk Read Operations/Sec" `
        -StartTime $StartTime -EndTime $EndTime -TimeGrain $TimeGrain `
        -AggregationType $Aggregation -ErrorAction SilentlyContinue

    $DiskRead = if ($DiskReadMetric.Data) {
        [math]::Round(($DiskReadMetric.Data | Measure-Object -Property $Aggregation -Average).Average, 2)
    } else { 'N/A' }

    [PSCustomObject]@{
        VMName = $VM.Name
        ResourceGroup = $VM.ResourceGroupName
        Size = $VM.HardwareProfile.VmSize
        "CPU%" = $Cpu
        "NetIn(GB)" = $NetIn
        "NetOut(GB)" = $NetOut
        "DiskRead/s" = $DiskRead
    }
}

Write-Host "`n=== VM Performance Metrics ($Aggregation over $Hours hours) ===" -ForegroundColor Green
$Results | Format-Table -AutoSize
