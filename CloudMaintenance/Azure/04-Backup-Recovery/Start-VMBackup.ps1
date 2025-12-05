#Requires -Modules Az.Accounts, Az.RecoveryServices
<#
.SYNOPSIS
    Initiates an on-demand backup for Azure VMs.
.DESCRIPTION
    Triggers immediate backup for specified VMs in a Recovery Services vault.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$VaultName,

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [string[]]$VMNames,
    [switch]$AllVMs,
    [int]$RetentionDays = 30
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

$Vault = Get-AzRecoveryServicesVault -Name $VaultName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
Set-AzRecoveryServicesVaultContext -Vault $Vault

Write-Host "Vault: $VaultName" -ForegroundColor Cyan

$Containers = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM

if (-not $Containers) {
    Write-Host "No protected VMs found in this vault."
    exit
}

$ExpiryDate = (Get-Date).AddDays($RetentionDays)

$BackupItems = foreach ($Container in $Containers) {
    Get-AzRecoveryServicesBackupItem -Container $Container -WorkloadType AzureVM
}

if (-not $AllVMs -and $VMNames) {
    $BackupItems = $BackupItems | Where-Object { $_.Name -in $VMNames }
}

if (-not $BackupItems) {
    Write-Host "No matching VMs found."
    exit
}

Write-Host "`nInitiating backup for $($BackupItems.Count) VM(s):"

foreach ($Item in $BackupItems) {
    Write-Host "  Starting backup: $($Item.Name)..." -NoNewline

    try {
        $Job = Backup-AzRecoveryServicesBackupItem -Item $Item -ExpiryDateTimeUTC $ExpiryDate
        Write-Host " Initiated (Job: $($Job.JobId))" -ForegroundColor Green
    }
    catch {
        Write-Host " Failed: $_" -ForegroundColor Red
    }
}

Write-Host "`nBackup jobs initiated. Monitor progress with Get-AzRecoveryServicesBackupJob"
