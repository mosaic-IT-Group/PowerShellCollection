# Monitoring & Reporting

Scripts for system monitoring and generating reports.

## Scripts

### Get-DiskSpaceReport.ps1

Generates disk space usage reports with configurable alert thresholds.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-ComputerName` | string[] | localhost | Target computers |
| `-WarningThresholdPercent` | int | 20 | Warning when free space below |
| `-CriticalThresholdPercent` | int | 10 | Critical when free space below |

**Example:**
```powershell
# Check local disk space
.\Get-DiskSpaceReport.ps1

# Check multiple servers
.\Get-DiskSpaceReport.ps1 -ComputerName "SRV01", "SRV02", "SRV03"

# Custom thresholds
.\Get-DiskSpaceReport.ps1 -WarningThresholdPercent 30 -CriticalThresholdPercent 15
```

**Output:**
```
Computer  Drive  Label   Size(GB)  Free(GB)  Free%  Status
--------  -----  -----   --------  --------  -----  ------
SRV01     C:     System  100.00    45.50     45.50  OK
SRV01     D:     Data    500.00    25.00     5.00   CRITICAL
SRV02     C:     System  100.00    18.00     18.00  WARNING
```

---

### Get-SystemResourceReport.ps1

Reports on CPU, memory usage, and top resource-consuming processes.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-ComputerName` | string[] | localhost | Target computers |
| `-TopProcesses` | int | 5 | Number of top processes to show |

**Example:**
```powershell
.\Get-SystemResourceReport.ps1 -TopProcesses 10
```

**Output:**
```
=== System Resources: SRV01 ===

CPU Usage: 35%
Memory: 12.5 GB / 16 GB (78.13% used)
Uptime: 15 days, 4 hours, 23 minutes

Top 5 Processes by CPU:
Name           Id    CPU     MemMB
----           --    ---     -----
sqlservr       1234  125.5   2048.3
w3wp           2345  45.2    512.7
```

---

### Get-FailedLoginReport.ps1

Analyzes failed login attempts and identifies potential brute force attacks.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Hours` | int | 24 | Hours of history |
| `-AlertThreshold` | int | 10 | Attempts from same source for alert |
| `-ExportPath` | string | - | CSV export path |

**Example:**
```powershell
# Quick review
.\Get-FailedLoginReport.ps1

# Extended analysis with export
.\Get-FailedLoginReport.ps1 -Hours 168 -ExportPath "C:\Reports\failed_logins.csv"
```

**Output:**
```
Total failed attempts: 47

Failed Attempts by User:
Name           Count
----           -----
administrator  25
admin          12
test           10

Failed Attempts by IP Address:
Name           Count
----           -----
192.168.1.100  30
10.0.0.50      17

WARNING: Potential brute force detected from:
  192.168.1.100: 30 attempts
```

---

### Send-MaintenanceReport.ps1

Generates and emails a comprehensive system health summary.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SmtpServer` | string | (required) | SMTP server address |
| `-To` | string | (required) | Recipient email |
| `-From` | string | maintenance@domain | Sender email |
| `-Subject` | string | (auto-generated) | Email subject |

**Example:**
```powershell
.\Send-MaintenanceReport.ps1 -SmtpServer "mail.domain.com" -To "admin@domain.com"
```

**Report Includes:**
- System information and uptime
- Disk space status for all drives
- Stopped automatic services
- Recent errors from event logs (last 24h)

**Scheduling:** Ideal for daily automated reports via Task Scheduler.

```powershell
# Example scheduled task
$Action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-File C:\Scripts\Send-MaintenanceReport.ps1 -SmtpServer mail.domain.com -To admin@domain.com"
$Trigger = New-ScheduledTaskTrigger -Daily -At 7am
Register-ScheduledTask -TaskName "Daily Maintenance Report" -Action $Action -Trigger $Trigger
```
