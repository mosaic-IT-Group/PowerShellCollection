# Backup & Recovery

Scripts for backup management and verification.

## Scripts

### Backup-SystemState.ps1

Creates a Windows System State backup using wbadmin.

**Requirements:**
- Windows Server Backup feature installed
- Windows Server OS

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-BackupTarget` | string | (required) | Destination path for backup |

**Example:**
```powershell
.\Backup-SystemState.ps1 -BackupTarget "E:\Backups"
```

**System State Includes:**
- Registry
- Boot files
- Active Directory (on DCs)
- SYSVOL (on DCs)
- Certificate Services (if installed)
- Cluster database (if applicable)

---

### Backup-Files.ps1

Creates compressed backups of specified folders with automatic retention.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SourcePaths` | string[] | (required) | Folders to back up |
| `-DestinationPath` | string | (required) | Backup destination |
| `-RetentionDays` | int | 30 | Days to keep old backups |

**Example:**
```powershell
# Backup multiple folders
.\Backup-Files.ps1 -SourcePaths "C:\Data", "C:\Config" -DestinationPath "E:\Backups" -RetentionDays 14
```

**Output:** Creates timestamped ZIP files like `Backup_20241205_143022.zip`

---

### Manage-ShadowCopies.ps1

Manages Volume Shadow Copy Service (VSS) snapshots.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Action` | string | List | List, Create, or Cleanup |
| `-Volume` | string | C: | Target volume |
| `-KeepCount` | int | 5 | Shadow copies to retain (Cleanup) |

**Example:**
```powershell
# List existing shadow copies
.\Manage-ShadowCopies.ps1

# Create new shadow copy
.\Manage-ShadowCopies.ps1 -Action Create -Volume "C:"

# Keep only 3 most recent copies
.\Manage-ShadowCopies.ps1 -Action Cleanup -Volume "C:" -KeepCount 3
```

---

### Test-BackupIntegrity.ps1

Verifies backup archive integrity by testing ZIP file structure.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-BackupPath` | string | (required) | Path containing backup archives |
| `-Detailed` | switch | false | Show detailed file listings |

**Example:**
```powershell
.\Test-BackupIntegrity.ps1 -BackupPath "E:\Backups"
```

**Output:**
```
Archive              Status  Files  SizeMB  LastModified
-------              ------  -----  ------  ------------
Backup_20241201.zip  Valid   150    45.2    12/01/2024
Backup_20241202.zip  Valid   152    46.1    12/02/2024
```

**Use Case:** Schedule weekly to verify backup health and alert on corruption.
