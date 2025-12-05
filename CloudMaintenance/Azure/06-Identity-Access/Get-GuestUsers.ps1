#Requires -Modules Az.Accounts, Az.Resources
<#
.SYNOPSIS
    Lists guest users with Azure access.
.DESCRIPTION
    Identifies external/guest users and their role assignments.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [switch]$ExportCsv,
    [string]$ExportPath = ".\GuestUsers.csv"
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Finding guest users with Azure access..." -ForegroundColor Cyan

# Get all role assignments
$Assignments = Get-AzRoleAssignment | Where-Object { $_.ObjectType -eq 'User' }

# Filter for guest users (typically have #EXT# in SignInName)
$GuestAssignments = $Assignments | Where-Object {
    $_.SignInName -like '*#EXT#*' -or $_.SignInName -like '*_*@*'
}

if (-not $GuestAssignments) {
    Write-Host "No guest users with role assignments found."
    exit
}

$Results = foreach ($Assignment in $GuestAssignments) {
    $Scope = switch -Regex ($Assignment.Scope) {
        '^/subscriptions/[^/]+$' { 'Subscription' }
        '^/subscriptions/[^/]+/resourceGroups/[^/]+$' { 'Resource Group' }
        default { 'Resource' }
    }

    [PSCustomObject]@{
        DisplayName = $Assignment.DisplayName
        Email = $Assignment.SignInName -replace '#EXT#.*', ''
        Role = $Assignment.RoleDefinitionName
        Scope = $Assignment.Scope.Split('/')[-1]
        ScopeLevel = $Scope
    }
}

Write-Host "`n=== Guest User Access Report ===" -ForegroundColor Green
Write-Host "Total assignments: $($Results.Count)"
Write-Host "Unique guests: $(($Results | Select-Object -Unique DisplayName).Count)"

Write-Host ""
$Results | Format-Table DisplayName, Email, Role, Scope, ScopeLevel -AutoSize

# Check for high-privilege guest access
$HighPriv = $Results | Where-Object {
    $_.Role -in @('Owner', 'Contributor', 'User Access Administrator')
}

if ($HighPriv) {
    Write-Host "`nGuests with high-privilege roles:" -ForegroundColor Yellow
    $HighPriv | Select-Object DisplayName, Email, Role, ScopeLevel | Format-Table -AutoSize
}

if ($ExportCsv) {
    $Results | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Exported to: $ExportPath"
}
