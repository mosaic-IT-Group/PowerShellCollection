#Requires -Modules Az.Accounts, Az.PolicyInsights
<#
.SYNOPSIS
    Reports on Azure Policy compliance status.
.DESCRIPTION
    Lists non-compliant resources by policy assignment.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [switch]$NonCompliantOnly,
    [switch]$ExportCsv,
    [string]$ExportPath = ".\PolicyCompliance.csv"
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Checking policy compliance..." -ForegroundColor Cyan

# Get policy states
$PolicyStates = Get-AzPolicyState -ErrorAction SilentlyContinue

if (-not $PolicyStates) {
    Write-Host "No policy data found."
    exit
}

# Summary by compliance state
$Summary = $PolicyStates | Group-Object ComplianceState

Write-Host "`n=== Policy Compliance Summary ===" -ForegroundColor Green
foreach ($State in $Summary) {
    $Color = switch ($State.Name) {
        'Compliant' { 'Green' }
        'NonCompliant' { 'Red' }
        default { 'Yellow' }
    }
    Write-Host "$($State.Name): $($State.Count)" -ForegroundColor $Color
}

# Get non-compliant resources
$NonCompliant = $PolicyStates | Where-Object { $_.ComplianceState -eq 'NonCompliant' }

if ($NonCompliant) {
    Write-Host "`nNon-Compliant Resources:" -ForegroundColor Yellow

    $Results = $NonCompliant | Select-Object @{N='Resource';E={$_.ResourceId.Split('/')[-1]}},
        @{N='ResourceGroup';E={$_.ResourceGroup}},
        @{N='ResourceType';E={$_.ResourceType.Split('/')[-1]}},
        PolicyAssignmentName,
        PolicyDefinitionName

    $Results | Format-Table -AutoSize

    # Group by policy
    Write-Host "`nNon-Compliance by Policy:"
    $NonCompliant | Group-Object PolicyDefinitionName | Sort-Object Count -Descending |
        Select-Object @{N='Policy';E={$_.Name}}, Count | Format-Table -AutoSize
}

if ($ExportCsv) {
    $PolicyStates | Select-Object ResourceId, ResourceGroup, ResourceType, ComplianceState,
        PolicyAssignmentName, PolicyDefinitionName |
        Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Exported to: $ExportPath"
}
