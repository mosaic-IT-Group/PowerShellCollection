#Requires -Modules Az.Accounts, Az.RecoveryServices
<#
.SYNOPSIS
    Reports on Azure Backup status.
.DESCRIPTION
    Lists backup jobs and protected items across Recovery Services vaults.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$VaultName,
    [int]$Days = 7
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Checking Azure Backup status..." -ForegroundColor Cyan

# Get Recovery Services vaults
$Vaults = if ($VaultName) {
    Get-AzRecoveryServicesVault -Name $VaultName
} else {
    Get-AzRecoveryServicesVault
}

if (-not $Vaults) {
    Write-Host "No Recovery Services vaults found."
    exit
}

foreach ($Vault in $Vaults) {
    Write-Host "`n=== Vault: $($Vault.Name) ===" -ForegroundColor Green

    Set-AzRecoveryServicesVaultContext -Vault $Vault

    # Get backup items
    $Containers = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -ErrorAction SilentlyContinue

    if ($Containers) {
        Write-Host "`nProtected VMs:"
        foreach ($Container in $Containers) {
            $Items = Get-AzRecoveryServicesBackupItem -Container $Container -WorkloadType AzureVM

            foreach ($Item in $Items) {
                $Status = switch ($Item.ProtectionStatus) {
                    'Healthy' { 'OK' }
                    'Unhealthy' { 'WARNING' }
                    default { $Item.ProtectionStatus }
                }

                [PSCustomObject]@{
                    VMName = $Item.Name
                    Status = $Status
                    LastBackup = $Item.LastBackupTime
                    PolicyName = $Item.ProtectionPolicyName
                } | Format-Table -AutoSize
            }
        }
    }

    # Get recent backup jobs
    $EndDate = Get-Date
    $StartDate = $EndDate.AddDays(-$Days)

    $Jobs = Get-AzRecoveryServicesBackupJob -From $StartDate -To $EndDate

    if ($Jobs) {
        Write-Host "`nRecent Backup Jobs (Last $Days days):"

        $JobSummary = $Jobs | Group-Object Status | Select-Object Name, Count
        $JobSummary | ForEach-Object {
            $Color = switch ($_.Name) {
                'Completed' { 'Green' }
                'Failed' { 'Red' }
                'InProgress' { 'Yellow' }
                default { 'White' }
            }
            Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor $Color
        }

        # Show failed jobs
        $FailedJobs = $Jobs | Where-Object { $_.Status -eq 'Failed' }
        if ($FailedJobs) {
            Write-Host "`nFailed Jobs:" -ForegroundColor Red
            $FailedJobs | Select-Object JobId, WorkloadName, Operation, StartTime, Status |
                Format-Table -AutoSize
        }
    }
}
