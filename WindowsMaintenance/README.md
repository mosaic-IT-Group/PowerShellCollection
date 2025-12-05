# Windows Maintenance Scripts

A collection of PowerShell scripts for automating common Windows system maintenance tasks. These scripts are designed for Windows Server and Windows 10/11 environments.

## Categories

| Folder | Description |
|--------|-------------|
| [01-Cleanup-Storage](01-Cleanup-Storage/) | Disk cleanup, temp files, browser cache, log rotation |
| [02-Updates-Patching](02-Updates-Patching/) | Windows Updates, driver updates, third-party software |
| [03-Security](03-Security/) | Malware scans, audit logs, certificates, password rotation |
| [04-Backup-Recovery](04-Backup-Recovery/) | System state, file backups, shadow copies |
| [05-Performance-Health](05-Performance-Health/) | Disk optimization, CHKDSK, service health, event logs |
| [06-ActiveDirectory](06-ActiveDirectory/) | Stale accounts, Group Policy, replication, DNS scavenging |
| [07-Networking](07-Networking/) | DHCP monitoring, DNS cache, share permissions |
| [08-Monitoring-Reporting](08-Monitoring-Reporting/) | Disk space, resource usage, failed logins, email reports |

## Requirements

- PowerShell 5.1 or later
- Administrator privileges (most scripts)
- Additional modules for specific scripts:
  - `PSWindowsUpdate` - for Windows Update automation
  - `ActiveDirectory` - for AD management scripts
  - `DhcpServer` - for DHCP monitoring
  - `DnsServer` - for DNS management

## Usage

Most scripts support common PowerShell parameters and can be run directly:

```powershell
# Run with default parameters
.\Clear-TempFiles.ps1

# Get help
Get-Help .\Clear-TempFiles.ps1 -Full

# Use WhatIf for testing
.\Remove-OldUserProfiles.ps1 -WhatIf
```

## Scheduling

These scripts are designed to be scheduled via:
- Windows Task Scheduler
- Group Policy
- SCCM/Intune
- Azure Automation

Example Task Scheduler setup:
```powershell
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Scripts\Clear-TempFiles.ps1"
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am
Register-ScheduledTask -TaskName "Weekly Cleanup" -Action $Action -Trigger $Trigger -RunLevel Highest
```

## License

Internal use only - Mosaic IT Group
