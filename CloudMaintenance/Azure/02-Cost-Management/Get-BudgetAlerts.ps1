#Requires -Modules Az.Accounts, Az.Consumption
<#
.SYNOPSIS
    Checks budget status and thresholds.
.DESCRIPTION
    Lists budgets and their current spend vs. limit.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [int]$WarningThreshold = 80
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Checking budget status..." -ForegroundColor Cyan

$Budgets = Get-AzConsumptionBudget -ErrorAction SilentlyContinue

if (-not $Budgets) {
    Write-Host "No budgets configured for this subscription."
    Write-Host "`nTo create a budget, use:"
    Write-Host "  New-AzConsumptionBudget -Name 'MonthlyBudget' -Amount 1000 -Category Cost -TimeGrain Monthly -StartDate (Get-Date -Day 1)"
    exit
}

$Results = foreach ($Budget in $Budgets) {
    $SpendPercent = if ($Budget.Amount -gt 0) {
        [math]::Round(($Budget.CurrentSpend.Amount / $Budget.Amount) * 100, 2)
    } else { 0 }

    $Status = if ($SpendPercent -ge 100) {
        'EXCEEDED'
    } elseif ($SpendPercent -ge $WarningThreshold) {
        'WARNING'
    } else {
        'OK'
    }

    [PSCustomObject]@{
        Name = $Budget.Name
        Amount = "$($Budget.Amount) $($Budget.CurrentSpend.Unit)"
        CurrentSpend = "$($Budget.CurrentSpend.Amount) $($Budget.CurrentSpend.Unit)"
        'Used%' = $SpendPercent
        Remaining = "$([math]::Round($Budget.Amount - $Budget.CurrentSpend.Amount, 2)) $($Budget.CurrentSpend.Unit)"
        TimeGrain = $Budget.TimeGrain
        Status = $Status
    }
}

Write-Host "`n=== Budget Status ===" -ForegroundColor Green
$Results | Format-Table -AutoSize

$Exceeded = $Results | Where-Object { $_.Status -eq 'EXCEEDED' }
$Warning = $Results | Where-Object { $_.Status -eq 'WARNING' }

if ($Exceeded) {
    Write-Host "EXCEEDED BUDGETS:" -ForegroundColor Red
    $Exceeded | Select-Object Name, Amount, CurrentSpend | Format-Table -AutoSize
}

if ($Warning) {
    Write-Host "WARNING - Approaching budget limit:" -ForegroundColor Yellow
    $Warning | Select-Object Name, 'Used%', Remaining | Format-Table -AutoSize
}
