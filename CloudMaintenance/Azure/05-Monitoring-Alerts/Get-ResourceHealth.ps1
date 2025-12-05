#Requires -Modules Az.Accounts, Az.ResourceGraph
<#
.SYNOPSIS
    Reports on Azure resource health status.
.DESCRIPTION
    Queries resource health for all resources in the subscription.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [switch]$UnhealthyOnly
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Checking resource health..." -ForegroundColor Cyan

# Use Resource Graph for efficient querying
$Query = @"
ResourceContainers
| where type == 'microsoft.resources/subscriptions/resourcegroups'
| project resourceGroup = name
"@

# Get resources with health status
$Resources = Get-AzResource | Select-Object Name, ResourceGroupName, ResourceType, Location

Write-Host "Found $($Resources.Count) resources"

# Check VM availability
$VMs = Get-AzVM -Status

$VMHealth = foreach ($VM in $VMs) {
    $Status = switch ($VM.PowerState) {
        'VM running' { 'Healthy' }
        'VM stopped' { 'Stopped' }
        'VM deallocated' { 'Deallocated' }
        default { 'Unknown' }
    }

    [PSCustomObject]@{
        ResourceType = 'Virtual Machine'
        Name = $VM.Name
        ResourceGroup = $VM.ResourceGroupName
        Status = $Status
        Details = $VM.PowerState
    }
}

# Check storage accounts
$StorageAccounts = Get-AzStorageAccount

$StorageHealth = foreach ($SA in $StorageAccounts) {
    [PSCustomObject]@{
        ResourceType = 'Storage Account'
        Name = $SA.StorageAccountName
        ResourceGroup = $SA.ResourceGroupName
        Status = if ($SA.ProvisioningState -eq 'Succeeded') { 'Healthy' } else { 'Unhealthy' }
        Details = $SA.ProvisioningState
    }
}

$AllHealth = $VMHealth + $StorageHealth

if ($UnhealthyOnly) {
    $AllHealth = $AllHealth | Where-Object { $_.Status -notin @('Healthy', 'Deallocated') }
}

Write-Host "`n=== Resource Health Report ===" -ForegroundColor Green

# Summary
$AllHealth | Group-Object Status | ForEach-Object {
    $Color = switch ($_.Name) {
        'Healthy' { 'Green' }
        'Running' { 'Green' }
        'Unhealthy' { 'Red' }
        'Stopped' { 'Yellow' }
        'Deallocated' { 'Gray' }
        default { 'White' }
    }
    Write-Host "$($_.Name): $($_.Count)" -ForegroundColor $Color
}

Write-Host ""
$AllHealth | Format-Table ResourceType, Name, ResourceGroup, Status, Details -AutoSize
