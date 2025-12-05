# Resource Management

Scripts for managing and optimizing Azure resources.

## Scripts

### Get-UnusedResources.ps1

Identifies unused Azure resources that may be incurring costs.

**Detects:**
- Unattached managed disks
- Unused public IP addresses
- Orphaned network interfaces
- Empty resource groups

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-ExportCsv` | switch | false | Export results to CSV |
| `-ExportPath` | string | .\UnusedResources.csv | CSV output path |

**Example:**
```powershell
.\Get-UnusedResources.ps1 -ExportCsv
```

---

### Remove-OldSnapshots.ps1

Removes disk snapshots older than the retention period.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-RetentionDays` | int | 30 | Keep snapshots newer than this |
| `-ResourceGroupName` | string | all | Filter by resource group |
| `-Force` | switch | false | Skip confirmation prompt |
| `-WhatIf` | switch | false | Preview without deleting |

**Example:**
```powershell
# Preview what would be deleted
.\Remove-OldSnapshots.ps1 -RetentionDays 14 -WhatIf

# Delete old snapshots
.\Remove-OldSnapshots.ps1 -RetentionDays 14 -Force
```

---

### Get-ResourceTags.ps1

Audits resource tagging compliance against required tags.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-RequiredTags` | string[] | Environment, Owner, CostCenter | Tags to check for |
| `-ResourceGroupName` | string | all | Filter by resource group |
| `-ExportCsv` | switch | false | Export results to CSV |

**Example:**
```powershell
# Check custom required tags
.\Get-ResourceTags.ps1 -RequiredTags "Environment", "Project", "Owner"
```

---

### Stop-UnusedVMs.ps1

Stops VMs based on tags or business hours schedule.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-TagName` | string | AutoShutdown | Tag to check |
| `-TagValue` | string | true | Required tag value |
| `-BusinessHoursOnly` | switch | false | Stop dev VMs outside hours |
| `-BusinessStart` | int | 8 | Business hours start (24h) |
| `-BusinessEnd` | int | 18 | Business hours end (24h) |

**Example:**
```powershell
# Stop VMs tagged for auto-shutdown
.\Stop-UnusedVMs.ps1

# Stop dev/test VMs outside business hours
.\Stop-UnusedVMs.ps1 -BusinessHoursOnly
```

**Tip:** Tag VMs with `Environment=Dev` and schedule this script to run at 6 PM to save on compute costs.
