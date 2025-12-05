#Requires -Modules Az.Accounts, Az.Resources, Az.ManagedServiceIdentity
<#
.SYNOPSIS
    Lists managed identities and their assignments.
.DESCRIPTION
    Reports on system and user-assigned managed identities across resources.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [ValidateSet('All', 'SystemAssigned', 'UserAssigned')]
    [string]$IdentityType = 'All'
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Finding managed identities..." -ForegroundColor Cyan

$Results = @()

# User-assigned managed identities
if ($IdentityType -in @('All', 'UserAssigned')) {
    $UserIdentities = Get-AzUserAssignedIdentity -ErrorAction SilentlyContinue

    foreach ($Identity in $UserIdentities) {
        $Roles = Get-AzRoleAssignment -ObjectId $Identity.PrincipalId -ErrorAction SilentlyContinue

        $Results += [PSCustomObject]@{
            Type = 'User-Assigned'
            Name = $Identity.Name
            ResourceGroup = $Identity.ResourceGroupName
            PrincipalId = $Identity.PrincipalId
            Roles = ($Roles.RoleDefinitionName -join ', ')
            AssignedTo = 'N/A'
        }
    }
}

# System-assigned managed identities (VMs)
if ($IdentityType -in @('All', 'SystemAssigned')) {
    $VMs = Get-AzVM

    foreach ($VM in $VMs) {
        if ($VM.Identity.Type -match 'SystemAssigned') {
            $Roles = Get-AzRoleAssignment -ObjectId $VM.Identity.PrincipalId -ErrorAction SilentlyContinue

            $Results += [PSCustomObject]@{
                Type = 'System-Assigned'
                Name = $VM.Name
                ResourceGroup = $VM.ResourceGroupName
                PrincipalId = $VM.Identity.PrincipalId
                Roles = ($Roles.RoleDefinitionName -join ', ')
                AssignedTo = 'VM'
            }
        }
    }

    # App Services
    $WebApps = Get-AzWebApp -ErrorAction SilentlyContinue

    foreach ($App in $WebApps) {
        if ($App.Identity.Type -match 'SystemAssigned') {
            $Roles = Get-AzRoleAssignment -ObjectId $App.Identity.PrincipalId -ErrorAction SilentlyContinue

            $Results += [PSCustomObject]@{
                Type = 'System-Assigned'
                Name = $App.Name
                ResourceGroup = $App.ResourceGroup
                PrincipalId = $App.Identity.PrincipalId
                Roles = ($Roles.RoleDefinitionName -join ', ')
                AssignedTo = 'App Service'
            }
        }
    }
}

Write-Host "`n=== Managed Identities ===" -ForegroundColor Green
Write-Host "Total: $($Results.Count)"

$Results | Group-Object Type | Select-Object Name, Count | Format-Table -AutoSize

$Results | Format-Table Type, Name, ResourceGroup, Roles, AssignedTo -AutoSize

# Check for identities without roles
$NoRoles = $Results | Where-Object { [string]::IsNullOrEmpty($_.Roles) }
if ($NoRoles) {
    Write-Host "`nIdentities without role assignments:" -ForegroundColor Yellow
    $NoRoles | Select-Object Type, Name | Format-Table -AutoSize
}
