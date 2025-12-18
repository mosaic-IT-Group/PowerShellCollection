# PowerShellCollection

A collection of PowerShell scripts for Windows system administration and automation tasks, maintained by Mosaic IT Group.

## Contents

### [WindowsMaintenance](WindowsMaintenance/)

Automated system maintenance scripts for Windows Server and Windows 10/11 environments.

| Category | Description |
|----------|-------------|
| [Cleanup & Storage](WindowsMaintenance/01-Cleanup-Storage/) | Temp files, browser cache, user profiles, log rotation |
| [Updates & Patching](WindowsMaintenance/02-Updates-Patching/) | Windows Updates, drivers, third-party software |
| [Security](WindowsMaintenance/03-Security/) | Malware scans, audit logs, certificates, password management |
| [Backup & Recovery](WindowsMaintenance/04-Backup-Recovery/) | System state, file backups, shadow copies, verification |
| [Performance & Health](WindowsMaintenance/05-Performance-Health/) | Disk optimization, CHKDSK, services, event logs |
| [Active Directory](WindowsMaintenance/06-ActiveDirectory/) | Stale accounts, Group Policy, replication, DNS scavenging |
| [Networking](WindowsMaintenance/07-Networking/) | DHCP, DNS, share permissions, connectivity testing |
| [Monitoring & Reporting](WindowsMaintenance/08-Monitoring-Reporting/) | Disk space, resources, failed logins, email reports |
| [Onboarding & Offboarding](WindowsMaintenance/09-Onboarding-Offboarding/) | User provisioning, account deprovisioning, audit trails |

### [CloudMaintenance](CloudMaintenance/)

Cloud infrastructure maintenance and automation scripts.

| Platform | Description |
|----------|-------------|
| [Azure](CloudMaintenance/Azure/) | Microsoft Azure maintenance scripts |

**Azure Categories:**
| Category | Description |
|----------|-------------|
| [Resource Management](CloudMaintenance/Azure/01-Resource-Management/) | Unused resources, snapshots, tags, VM scheduling |
| [Cost Management](CloudMaintenance/Azure/02-Cost-Management/) | Cost reports, budgets, reserved instances, right-sizing |
| [Security & Compliance](CloudMaintenance/Azure/03-Security-Compliance/) | Security Center, Key Vault, storage security, policies |
| [Backup & Recovery](CloudMaintenance/Azure/04-Backup-Recovery/) | Backup status, on-demand backups, recovery points |
| [Monitoring & Alerts](CloudMaintenance/Azure/05-Monitoring-Alerts/) | Resource health, alerts, metrics, activity logs |
| [Identity & Access](CloudMaintenance/Azure/06-Identity-Access/) | RBAC, service principals, managed identities, guests |
| [Networking](CloudMaintenance/Azure/07-Networking/) | NSG rules, public IPs, VNet peerings, connectivity |

## Requirements

- PowerShell 5.1 or later
- Administrator privileges (most scripts)
- Windows Server 2016+ or Windows 10/11

## Usage

```powershell
# Run a script
.\ScriptName.ps1

# Get help for any script
Get-Help .\ScriptName.ps1 -Full

# Test with WhatIf (where supported)
.\ScriptName.ps1 -WhatIf
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
