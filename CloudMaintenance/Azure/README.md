# Azure Maintenance Scripts

PowerShell scripts for Azure cloud infrastructure maintenance and monitoring.

## Categories

| Folder | Description |
|--------|-------------|
| [01-Resource-Management](01-Resource-Management/) | Unused resources, snapshots, tags, VM scheduling |
| [02-Cost-Management](02-Cost-Management/) | Cost reports, budgets, reserved instances, right-sizing |
| [03-Security-Compliance](03-Security-Compliance/) | Security Center, Key Vault, storage security, policies |
| [04-Backup-Recovery](04-Backup-Recovery/) | Backup status, on-demand backups, recovery points |
| [05-Monitoring-Alerts](05-Monitoring-Alerts/) | Resource health, alerts, metrics, activity logs |
| [06-Identity-Access](06-Identity-Access/) | RBAC, service principals, managed identities, guests |
| [07-Networking](07-Networking/) | NSG rules, public IPs, VNet peerings, connectivity |

## Requirements

- PowerShell 5.1+ or PowerShell 7+
- Az PowerShell modules:
  ```powershell
  Install-Module Az -Scope CurrentUser
  ```
- Azure subscription with appropriate permissions
- Authenticated session (`Connect-AzAccount`)

## Common Modules Used

| Module | Purpose |
|--------|---------|
| Az.Accounts | Authentication and subscription management |
| Az.Resources | Resource management and RBAC |
| Az.Compute | Virtual machines and disks |
| Az.Network | Networking resources |
| Az.Storage | Storage accounts |
| Az.Monitor | Metrics and alerts |
| Az.RecoveryServices | Azure Backup |
| Az.Security | Security Center |
| Az.KeyVault | Key Vault management |
| Az.Billing | Cost and usage data |

## Usage

```powershell
# Connect to Azure
Connect-AzAccount

# Select subscription
Set-AzContext -SubscriptionId "your-subscription-id"

# Run a script
.\Get-UnusedResources.ps1

# Get help
Get-Help .\Get-UnusedResources.ps1 -Full

# Export results
.\Get-CostReport.ps1 -ExportCsv -ExportPath "C:\Reports\costs.csv"
```

## Scheduling with Azure Automation

These scripts can be run as Azure Automation runbooks:

1. Create an Automation Account
2. Import required Az modules
3. Create a Run As account or Managed Identity
4. Import scripts as runbooks
5. Create schedules

## License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file for details.
