#Requires -Modules Az.Accounts, Az.Billing
<#
.SYNOPSIS
    Generates Azure cost report.
.DESCRIPTION
    Retrieves cost data grouped by resource group, service, or tags.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [ValidateSet('ResourceGroup', 'Service', 'Tag')]
    [string]$GroupBy = 'ResourceGroup',
    [int]$Days = 30,
    [string]$TagName = 'CostCenter',
    [switch]$ExportCsv,
    [string]$ExportPath = ".\CostReport.csv"
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

$EndDate = Get-Date
$StartDate = $EndDate.AddDays(-$Days)

Write-Host "Retrieving costs from $($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))..." -ForegroundColor Cyan

# Get consumption usage
$Usage = Get-AzConsumptionUsageDetail -StartDate $StartDate -EndDate $EndDate -ErrorAction Stop

if (-not $Usage) {
    Write-Host "No usage data found for the specified period."
    exit
}

$Results = switch ($GroupBy) {
    'ResourceGroup' {
        $Usage | Group-Object InstanceName | ForEach-Object {
            $RG = ($_.Group[0].InstanceId -split '/')[4]
            [PSCustomObject]@{
                ResourceGroup = $RG
                Resource = $_.Name
                Cost = [math]::Round(($_.Group | Measure-Object -Property PretaxCost -Sum).Sum, 2)
                Currency = $_.Group[0].Currency
            }
        } | Sort-Object Cost -Descending
    }
    'Service' {
        $Usage | Group-Object ConsumedService | ForEach-Object {
            [PSCustomObject]@{
                Service = $_.Name
                Cost = [math]::Round(($_.Group | Measure-Object -Property PretaxCost -Sum).Sum, 2)
                Currency = $_.Group[0].Currency
                ResourceCount = $_.Count
            }
        } | Sort-Object Cost -Descending
    }
    'Tag' {
        $Usage | Group-Object { $_.Tags[$TagName] } | ForEach-Object {
            [PSCustomObject]@{
                TagValue = if ($_.Name) { $_.Name } else { 'Untagged' }
                Cost = [math]::Round(($_.Group | Measure-Object -Property PretaxCost -Sum).Sum, 2)
                Currency = $_.Group[0].Currency
                ResourceCount = $_.Count
            }
        } | Sort-Object Cost -Descending
    }
}

$TotalCost = [math]::Round(($Usage | Measure-Object -Property PretaxCost -Sum).Sum, 2)

Write-Host "`n=== Cost Report (Last $Days Days) ===" -ForegroundColor Green
Write-Host "Total Cost: $TotalCost $($Usage[0].Currency)`n"

$Results | Format-Table -AutoSize

if ($ExportCsv) {
    $Results | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Exported to: $ExportPath"
}
