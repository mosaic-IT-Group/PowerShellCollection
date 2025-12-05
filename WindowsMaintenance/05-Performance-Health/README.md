# Performance & Health

Scripts for system performance optimization and health monitoring.

## Scripts

### Optimize-Disk.ps1

Performs disk optimization appropriate for the drive type.

**Behavior:**
- **SSD:** Runs TRIM operation to maintain performance
- **HDD:** Runs defragmentation to reduce file fragmentation

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-DriveLetter` | string | C | Drive to optimize |

**Example:**
```powershell
.\Optimize-Disk.ps1 -DriveLetter D
```

**Note:** Automatically detects drive type and runs the appropriate optimization.

---

### Start-DiskCheck.ps1

Runs CHKDSK to check and repair disk errors.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-DriveLetter` | string | C | Drive to check |
| `-ScheduleReboot` | switch | false | Auto-reboot for system drive repair |

**Example:**
```powershell
# Check disk (read-only scan)
.\Start-DiskCheck.ps1 -DriveLetter C

# Check and schedule repair on reboot
.\Start-DiskCheck.ps1 -DriveLetter C -ScheduleReboot
```

**Note:** System drive (C:) requires offline repair, which runs at next boot.

---

### Get-EventLogErrors.ps1

Retrieves errors and warnings from Windows Event Logs.

**Logs Monitored:**
- System
- Application

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Hours` | int | 24 | Hours of history |
| `-Level` | string | Both | Error, Warning, or Both |

**Example:**
```powershell
# Get all errors and warnings from last 24 hours
.\Get-EventLogErrors.ps1

# Get only errors from last week
.\Get-EventLogErrors.ps1 -Hours 168 -Level Error
```

**Output:** Lists events and shows top error sources for quick triage.

---

### Get-ServiceHealth.ps1

Monitors critical Windows services and optionally restarts stopped services.

**Default Services Monitored:**
- Windows Update (wuauserv)
- BITS
- Print Spooler
- Windows Time
- Event Log
- Task Scheduler
- Windows Defender
- DHCP Client
- DNS Client

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Services` | string[] | (defaults) | Service names to check |
| `-AutoRestart` | switch | false | Restart stopped services |

**Example:**
```powershell
# Check default services
.\Get-ServiceHealth.ps1

# Check and restart stopped services
.\Get-ServiceHealth.ps1 -AutoRestart

# Check custom service list
.\Get-ServiceHealth.ps1 -Services "MSSQLSERVER", "SQLAgent"
```

---

### Schedule-Reboot.ps1

Creates a scheduled task to reboot the system at a specified time.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-RebootTime` | datetime | (required) | When to reboot |
| `-Reason` | string | Scheduled maintenance reboot | Message shown to users |
| `-Cancel` | switch | false | Cancel scheduled reboot |

**Example:**
```powershell
# Schedule reboot for Sunday 3 AM
.\Schedule-Reboot.ps1 -RebootTime "2024-12-08 03:00"

# Cancel scheduled reboot
.\Schedule-Reboot.ps1 -Cancel
```

**Note:** Users receive a 60-second warning before the reboot occurs.
