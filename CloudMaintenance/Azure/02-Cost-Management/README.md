# Cost Management

Scripts for monitoring and optimizing Azure spending.

## Scripts

### Get-CostReport.ps1

Generates cost reports grouped by various dimensions.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-GroupBy` | string | ResourceGroup | ResourceGroup, Service, or Tag |
| `-Days` | int | 30 | Days of cost data |
| `-TagName` | string | CostCenter | Tag for grouping (if GroupBy=Tag) |
| `-ExportCsv` | switch | false | Export results to CSV |

**Example:**
```powershell
# Cost by service
.\Get-CostReport.ps1 -GroupBy Service -Days 7

# Cost by cost center tag
.\Get-CostReport.ps1 -GroupBy Tag -TagName "CostCenter"
```

---

### Get-BudgetAlerts.ps1

Checks budget status and spending thresholds.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-WarningThreshold` | int | 80 | Percentage to trigger warning |

**Example:**
```powershell
.\Get-BudgetAlerts.ps1 -WarningThreshold 70
```

**Output:**
```
Name           Amount       CurrentSpend   Used%  Status
----           ------       ------------   -----  ------
MonthlyBudget  $5000 USD    $4250 USD      85.00  WARNING
ProjectX       $1000 USD    $450 USD       45.00  OK
```

---

### Get-ReservedInstanceUsage.ps1

Reports on Reserved Instance utilization.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Days` | int | 30 | Analysis period |
| `-UtilizationThreshold` | int | 80 | Underutilization threshold |

**Example:**
```powershell
.\Get-ReservedInstanceUsage.ps1
```

**Checks:**
- Current reservations
- Expiring reservations
- Utilization percentage

---

### Resize-UnderutilizedVMs.ps1

Identifies VMs that can be downsized based on usage metrics.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-Days` | int | 14 | Days of metrics to analyze |
| `-CpuThreshold` | int | 20 | Average CPU below this = underutilized |
| `-MemoryThreshold` | int | 30 | Average memory below this = underutilized |
| `-ExportCsv` | switch | false | Export results to CSV |

**Example:**
```powershell
.\Resize-UnderutilizedVMs.ps1 -Days 30 -CpuThreshold 15
```

**Output:**
```
Name       ResourceGroup  CurrentSize      AvgCPU%  MaxCPU%  Recommendation
----       -------------  -----------      -------  -------  --------------
vm-web-01  rg-prod        Standard_D4s_v3  8.5      25.2     Consider downsizing
vm-db-01   rg-prod        Standard_D8s_v3  45.2     78.5     Right-sized
```

**Tip:** Review VMs with consistently low CPU/memory usage and consider moving to a smaller VM size to reduce costs.
