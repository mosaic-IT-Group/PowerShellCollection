#Requires -Modules Az.Accounts, Az.Resources
<#
.SYNOPSIS
    Audits Azure RBAC role assignments.
.DESCRIPTION
    Lists role assignments at subscription, resource group, or resource level.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$ResourceGroupName,
    [ValidateSet('All', 'User', 'Group', 'ServicePrincipal')]
    [string]$PrincipalType = 'All',
    [switch]$ExportCsv,
    [string]$ExportPath = ".\RoleAssignments.csv"
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Retrieving role assignments..." -ForegroundColor Cyan

$Params = @{}
if ($ResourceGroupName) {
    $Params.ResourceGroupName = $ResourceGroupName
}

$Assignments = Get-AzRoleAssignment @Params

if ($PrincipalType -ne 'All') {
    $Assignments = $Assignments | Where-Object { $_.ObjectType -eq $PrincipalType }
}

$Results = foreach ($Assignment in $Assignments) {
    $Scope = switch -Regex ($Assignment.Scope) {
        '^/subscriptions/[^/]+$' { 'Subscription' }
        '^/subscriptions/[^/]+/resourceGroups/[^/]+$' { 'Resource Group' }
        default { 'Resource' }
    }

    [PSCustomObject]@{
        DisplayName = $Assignment.DisplayName
        SignInName = $Assignment.SignInName
        ObjectType = $Assignment.ObjectType
        RoleDefinitionName = $Assignment.RoleDefinitionName
        Scope = $Assignment.Scope.Split('/')[-1]
        ScopeLevel = $Scope
    }
}

Write-Host "`n=== Role Assignments ===" -ForegroundColor Green
Write-Host "Total: $($Results.Count)"

# Summary by role
Write-Host "`nBy Role:"
$Results | Group-Object RoleDefinitionName | Sort-Object Count -Descending |
    Select-Object Name, Count | Format-Table -AutoSize

# Summary by principal type
Write-Host "By Principal Type:"
$Results | Group-Object ObjectType |
    Select-Object Name, Count | Format-Table -AutoSize

Write-Host "Assignments:"
$Results | Format-Table DisplayName, ObjectType, RoleDefinitionName, Scope, ScopeLevel -AutoSize

# Check for Owner/Contributor at subscription level
$HighPriv = $Results | Where-Object {
    $_.RoleDefinitionName -in @('Owner', 'Contributor') -and
    $_.ScopeLevel -eq 'Subscription'
}

if ($HighPriv) {
    Write-Host "`nHigh-privilege assignments at subscription level:" -ForegroundColor Yellow
    $HighPriv | Select-Object DisplayName, RoleDefinitionName | Format-Table -AutoSize
}

if ($ExportCsv) {
    $Results | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Exported to: $ExportPath"
}
