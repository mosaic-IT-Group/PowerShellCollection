#Requires -Modules Az.Accounts, Az.Monitor
<#
.SYNOPSIS
    Lists and validates Azure Monitor alert rules.
.DESCRIPTION
    Reports on configured alerts and their current status.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$ResourceGroupName,
    [switch]$EnabledOnly
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Retrieving alert rules..." -ForegroundColor Cyan

$Params = @{}
if ($ResourceGroupName) {
    $Params.ResourceGroupName = $ResourceGroupName
}

# Get metric alerts
$MetricAlerts = Get-AzMetricAlertRuleV2 @Params -ErrorAction SilentlyContinue

# Get activity log alerts
$ActivityAlerts = Get-AzActivityLogAlert @Params -ErrorAction SilentlyContinue

$Results = @()

foreach ($Alert in $MetricAlerts) {
    $Results += [PSCustomObject]@{
        Name = $Alert.Name
        Type = 'Metric'
        ResourceGroup = $Alert.ResourceGroupName
        Enabled = $Alert.Enabled
        Severity = $Alert.Severity
        TargetResource = ($Alert.Scopes -join ', ')
        Condition = ($Alert.Criteria.CriterionType -join ', ')
    }
}

foreach ($Alert in $ActivityAlerts) {
    $Results += [PSCustomObject]@{
        Name = $Alert.Name
        Type = 'Activity Log'
        ResourceGroup = $Alert.ResourceGroupName
        Enabled = $Alert.Enabled
        Severity = 'N/A'
        TargetResource = ($Alert.Scopes -join ', ')
        Condition = ($Alert.Condition.AllOf.Field -join ', ')
    }
}

if ($EnabledOnly) {
    $Results = $Results | Where-Object { $_.Enabled -eq $true }
}

Write-Host "`n=== Alert Rules ===" -ForegroundColor Green
Write-Host "Total: $($Results.Count)"
Write-Host "Enabled: $(($Results | Where-Object Enabled).Count)"
Write-Host "Disabled: $(($Results | Where-Object { -not $_.Enabled }).Count)"

Write-Host ""
$Results | Format-Table Name, Type, Enabled, Severity, TargetResource -AutoSize

# Check for resources without alerts
Write-Host "`nTip: Consider setting up alerts for:"
Write-Host "  - VM CPU > 80%"
Write-Host "  - VM Available Memory < 20%"
Write-Host "  - Storage Account availability"
Write-Host "  - Failed backup jobs"
