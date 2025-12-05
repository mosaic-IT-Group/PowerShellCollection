#Requires -Modules Az.Accounts, Az.Compute, Az.RecoveryServices
<#
.SYNOPSIS
    Identifies VMs not protected by Azure Backup.
.DESCRIPTION
    Compares running VMs against protected items in Recovery Services vaults.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [switch]$ExportCsv,
    [string]$ExportPath = ".\UnprotectedVMs.csv"
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Finding unprotected VMs..." -ForegroundColor Cyan

# Get all VMs
$AllVMs = Get-AzVM | Select-Object Name, ResourceGroupName, Location

# Get all protected VMs from all vaults
$ProtectedVMs = @()

$Vaults = Get-AzRecoveryServicesVault

foreach ($Vault in $Vaults) {
    Set-AzRecoveryServicesVaultContext -Vault $Vault

    $Containers = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -ErrorAction SilentlyContinue

    foreach ($Container in $Containers) {
        $Items = Get-AzRecoveryServicesBackupItem -Container $Container -WorkloadType AzureVM -ErrorAction SilentlyContinue
        foreach ($Item in $Items) {
            $ProtectedVMs += $Item.Name
        }
    }
}

$ProtectedVMs = $ProtectedVMs | Select-Object -Unique

# Find unprotected
$Unprotected = $AllVMs | Where-Object { $_.Name -notin $ProtectedVMs }

Write-Host "`n=== VM Backup Coverage ===" -ForegroundColor Green
Write-Host "Total VMs: $($AllVMs.Count)"
Write-Host "Protected: $($ProtectedVMs.Count)" -ForegroundColor Green
Write-Host "Unprotected: $($Unprotected.Count)" -ForegroundColor $(if ($Unprotected.Count -gt 0) { 'Yellow' } else { 'Green' })

if ($Unprotected) {
    Write-Host "`nUnprotected VMs:"
    $Unprotected | Format-Table Name, ResourceGroupName, Location -AutoSize
}

if ($ExportCsv -and $Unprotected) {
    $Unprotected | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Exported to: $ExportPath"
}
