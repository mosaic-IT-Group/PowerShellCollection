# Monitoring & Alerts

Scripts for Azure monitoring and alerting.

## Scripts

### Get-ResourceHealth.ps1

Reports on Azure resource health status.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-UnhealthyOnly` | switch | false | Show only unhealthy resources |

**Example:**
```powershell
.\Get-ResourceHealth.ps1 -UnhealthyOnly
```

**Checks:**
- VM power state
- Storage account provisioning state
- Other resource health indicators

---

### Get-AlertRules.ps1

Lists and validates Azure Monitor alert rules.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-ResourceGroupName` | string | all | Filter by resource group |
| `-EnabledOnly` | switch | false | Show only enabled alerts |

**Example:**
```powershell
.\Get-AlertRules.ps1 -EnabledOnly
```

**Output:**
```
=== Alert Rules ===
Total: 15
Enabled: 12
Disabled: 3

Name                  Type        Enabled  Severity  TargetResource
----                  ----        -------  --------  --------------
CPU-High-Alert        Metric      True     2         vm-web-01
Memory-Low-Alert      Metric      True     2         vm-db-01
Failed-Backup-Alert   Activity    True     1         rsv-prod
```

---

### Get-VMMetrics.ps1

Retrieves performance metrics for Azure VMs.

**Metrics:**
- CPU percentage
- Network in/out (GB)
- Disk operations/sec

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-ResourceGroupName` | string | all | Filter by resource group |
| `-VMName` | string | all | Specific VM |
| `-Hours` | int | 24 | Time range |
| `-Aggregation` | string | Average | Average, Maximum, or Minimum |

**Example:**
```powershell
# Get max CPU for last week
.\Get-VMMetrics.ps1 -Hours 168 -Aggregation Maximum
```

**Output:**
```
VMName     ResourceGroup  Size            CPU%   NetIn(GB)  NetOut(GB)
------     -------------  ----            ----   ---------  ----------
vm-web-01  rg-prod        Standard_D4s    35.2   12.5       8.3
vm-db-01   rg-prod        Standard_D8s    68.5   5.2        2.1
```

---

### Get-ActivityLog.ps1

Retrieves Azure Activity Log entries.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-Hours` | int | 24 | Time range |
| `-ResourceGroupName` | string | all | Filter by resource group |
| `-OperationType` | string | All | All, Write, Delete, or Action |
| `-Status` | string | All | All, Succeeded, or Failed |
| `-ExportCsv` | switch | false | Export results to CSV |

**Example:**
```powershell
# Get failed operations
.\Get-ActivityLog.ps1 -Status Failed -Hours 48

# Get all delete operations
.\Get-ActivityLog.ps1 -OperationType Delete
```
