# Cleanup & Storage

Scripts for managing disk space and removing unnecessary files.

## Scripts

### Clear-TempFiles.ps1

Removes temporary files from Windows system folders.

**Targets:**
- User temp folder (`%TEMP%`)
- Windows temp folder (`C:\Windows\Temp`)
- Windows Update download cache

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-DaysOld` | int | 7 | Only delete files older than this many days |

**Example:**
```powershell
# Delete temp files older than 14 days
.\Clear-TempFiles.ps1 -DaysOld 14
```

---

### Clear-RecycleBin.ps1

Empties the Recycle Bin for all users on the system.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Force` | switch | false | Skip confirmation prompt |

**Example:**
```powershell
.\Clear-RecycleBin.ps1 -Force
```

---

### Remove-OldUserProfiles.ps1

Identifies and removes local user profiles that haven't been used recently. Useful for shared workstations or terminal servers.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-DaysInactive` | int | 90 | Remove profiles inactive for this many days |
| `-ExcludeUsers` | string[] | Administrator, Default, Public | Profiles to never remove |
| `-WhatIf` | switch | false | Preview changes without removing |

**Example:**
```powershell
# Preview profiles that would be removed
.\Remove-OldUserProfiles.ps1 -DaysInactive 60 -WhatIf

# Remove profiles inactive for 60 days, excluding service accounts
.\Remove-OldUserProfiles.ps1 -DaysInactive 60 -ExcludeUsers Administrator,svc_backup
```

---

### Clear-BrowserCache.ps1

Clears cached data from web browsers for all user profiles on the machine.

**Supported Browsers:**
- Google Chrome
- Microsoft Edge
- Mozilla Firefox

**Example:**
```powershell
.\Clear-BrowserCache.ps1
```

**Note:** Close browsers before running for best results.

---

### Rotate-Logs.ps1

Compresses old log files and removes aged archives to manage log storage.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-LogPath` | string | C:\Logs | Directory containing log files |
| `-CompressAfterDays` | int | 7 | Compress logs older than this |
| `-DeleteAfterDays` | int | 30 | Delete archives older than this |

**Example:**
```powershell
# Rotate IIS logs
.\Rotate-Logs.ps1 -LogPath "C:\inetpub\logs\LogFiles" -CompressAfterDays 3 -DeleteAfterDays 14
```

**Behavior:**
1. Finds `.log` files older than `CompressAfterDays`
2. Compresses each to a dated `.zip` in an `Archive` subfolder
3. Deletes original log file
4. Removes archives older than `DeleteAfterDays`
