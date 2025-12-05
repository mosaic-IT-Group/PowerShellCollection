# Backup & Recovery

Scripts for Azure Backup management and monitoring.

## Scripts

### Get-BackupStatus.ps1

Reports on Azure Backup status across Recovery Services vaults.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-VaultName` | string | all | Filter by vault name |
| `-Days` | int | 7 | Days of job history |

**Example:**
```powershell
.\Get-BackupStatus.ps1 -Days 14
```

**Output:**
```
=== Vault: rsv-prod-001 ===

Protected VMs:
VMName       Status  LastBackup           PolicyName
------       ------  ----------           ----------
vm-web-01    OK      2024-12-04 02:00:00  DailyBackup
vm-db-01     OK      2024-12-04 02:15:00  DailyBackup

Recent Backup Jobs (Last 7 days):
Completed: 14
Failed: 0
InProgress: 1
```

---

### Start-VMBackup.ps1

Initiates on-demand backup for Azure VMs.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-VaultName` | string | (required) | Recovery Services vault |
| `-ResourceGroupName` | string | (required) | Vault resource group |
| `-VMNames` | string[] | - | Specific VMs to back up |
| `-AllVMs` | switch | false | Back up all protected VMs |
| `-RetentionDays` | int | 30 | Backup retention period |

**Example:**
```powershell
# Backup specific VM
.\Start-VMBackup.ps1 -VaultName "rsv-prod" -ResourceGroupName "rg-backup" -VMNames "vm-critical-01"

# Backup all VMs in vault
.\Start-VMBackup.ps1 -VaultName "rsv-prod" -ResourceGroupName "rg-backup" -AllVMs
```

---

### Get-UnprotectedResources.ps1

Identifies VMs not protected by Azure Backup.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-ExportCsv` | switch | false | Export results to CSV |

**Example:**
```powershell
.\Get-UnprotectedResources.ps1
```

**Output:**
```
=== VM Backup Coverage ===
Total VMs: 25
Protected: 20
Unprotected: 5

Unprotected VMs:
Name          ResourceGroupName  Location
----          -----------------  --------
vm-dev-01     rg-dev             eastus
vm-test-02    rg-test            eastus
```

---

### Remove-OldRecoveryPoints.ps1

Cleans up old backup recovery points.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-VaultName` | string | (required) | Recovery Services vault |
| `-ResourceGroupName` | string | (required) | Vault resource group |
| `-RetentionDays` | int | 90 | Keep points newer than this |
| `-Force` | switch | false | Skip confirmation |
| `-WhatIf` | switch | false | Preview without deleting |

**Example:**
```powershell
# Preview cleanup
.\Remove-OldRecoveryPoints.ps1 -VaultName "rsv-prod" -ResourceGroupName "rg-backup" -RetentionDays 60 -WhatIf
```

**Note:** Use caution - deleted recovery points cannot be restored.
