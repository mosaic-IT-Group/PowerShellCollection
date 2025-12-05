#Requires -Modules Az.Accounts, Az.Network
<#
.SYNOPSIS
    Audits Network Security Group rules.
.DESCRIPTION
    Lists NSG rules and identifies overly permissive configurations.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$ResourceGroupName,
    [switch]$OpenRulesOnly,
    [switch]$ExportCsv,
    [string]$ExportPath = ".\NSGRules.csv"
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Auditing Network Security Groups..." -ForegroundColor Cyan

$Params = @{}
if ($ResourceGroupName) {
    $Params.ResourceGroupName = $ResourceGroupName
}

$NSGs = Get-AzNetworkSecurityGroup @Params

$Results = @()

foreach ($NSG in $NSGs) {
    foreach ($Rule in $NSG.SecurityRules) {
        $IsOpen = $Rule.SourceAddressPrefix -eq '*' -or
                  $Rule.SourceAddressPrefix -eq 'Internet' -or
                  $Rule.SourceAddressPrefix -eq '0.0.0.0/0'

        $RiskLevel = if ($Rule.Access -eq 'Allow' -and $Rule.Direction -eq 'Inbound') {
            if ($IsOpen -and $Rule.DestinationPortRange -eq '*') {
                'Critical'
            } elseif ($IsOpen -and $Rule.DestinationPortRange -in @('22', '3389', '445')) {
                'High'
            } elseif ($IsOpen) {
                'Medium'
            } else {
                'Low'
            }
        } else {
            'Low'
        }

        $Results += [PSCustomObject]@{
            NSG = $NSG.Name
            ResourceGroup = $NSG.ResourceGroupName
            RuleName = $Rule.Name
            Priority = $Rule.Priority
            Direction = $Rule.Direction
            Access = $Rule.Access
            SourceAddress = $Rule.SourceAddressPrefix
            DestPort = $Rule.DestinationPortRange
            Protocol = $Rule.Protocol
            RiskLevel = $RiskLevel
        }
    }
}

if ($OpenRulesOnly) {
    $Results = $Results | Where-Object { $_.RiskLevel -in @('Critical', 'High', 'Medium') }
}

Write-Host "`n=== NSG Rules Audit ===" -ForegroundColor Green
Write-Host "Total Rules: $($Results.Count)"

# Risk summary
$Results | Group-Object RiskLevel | ForEach-Object {
    $Color = switch ($_.Name) {
        'Critical' { 'Red' }
        'High' { 'Yellow' }
        'Medium' { 'DarkYellow' }
        'Low' { 'Green' }
    }
    Write-Host "$($_.Name): $($_.Count)" -ForegroundColor $Color
}

Write-Host ""
$Results | Format-Table NSG, RuleName, Direction, Access, SourceAddress, DestPort, RiskLevel -AutoSize

# Alert on critical rules
$Critical = $Results | Where-Object { $_.RiskLevel -eq 'Critical' }
if ($Critical) {
    Write-Host "`nCRITICAL: Rules allowing all ports from any source:" -ForegroundColor Red
    $Critical | Select-Object NSG, RuleName, SourceAddress, DestPort | Format-Table -AutoSize
}

if ($ExportCsv) {
    $Results | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Exported to: $ExportPath"
}
