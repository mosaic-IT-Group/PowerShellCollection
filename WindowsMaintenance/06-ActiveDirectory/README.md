# Active Directory

Scripts for Active Directory maintenance and monitoring.

## Requirements

- Active Directory PowerShell module
- Domain Admin or delegated permissions
- Run from a domain-joined machine

## Scripts

### Remove-StaleADObjects.ps1

Identifies and manages stale (inactive) computer and user accounts.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-InactiveDays` | int | 90 | Days since last login |
| `-ObjectType` | string | Both | Computers, Users, or Both |
| `-Action` | string | Report | Report, Disable, or Delete |
| `-ExcludeOU` | string | - | OU path to exclude |

**Example:**
```powershell
# Report only - see what would be affected
.\Remove-StaleADObjects.ps1 -InactiveDays 90 -Action Report

# Disable stale computer accounts
.\Remove-StaleADObjects.ps1 -ObjectType Computers -Action Disable

# Delete stale users, exclude service accounts OU
.\Remove-StaleADObjects.ps1 -ObjectType Users -Action Delete -ExcludeOU "OU=ServiceAccounts"
```

**Best Practice:** Always run with `-Action Report` first, then `-Action Disable`, wait 30 days, then delete.

---

### Update-GroupPolicy.ps1

Forces Group Policy refresh on local or remote computers.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-ComputerName` | string[] | localhost | Target computers |
| `-Force` | switch | false | Force full policy refresh |

**Example:**
```powershell
# Update local computer
.\Update-GroupPolicy.ps1 -Force

# Update multiple remote computers
.\Update-GroupPolicy.ps1 -ComputerName "PC01", "PC02", "PC03" -Force
```

---

### Get-ADReplicationStatus.ps1

Monitors Active Directory replication health between domain controllers.

**Checks:**
- Lists all domain controllers
- Replication partner status
- Last successful replication time
- Replication failures
- Replication queue depth

**Example:**
```powershell
.\Get-ADReplicationStatus.ps1
```

**Output:**
- DC list with site and GC status
- Partner replication status table
- Detailed replication summary (via repadmin)
- Current replication queue

**Alert Conditions:** Script warns if any replication failures are detected.

---

### Start-DNSScavenging.ps1

Manages DNS scavenging to remove stale DNS records.

**Requirements:**
- DnsServer PowerShell module
- DNS Server role

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-DnsServer` | string | localhost | DNS server name |
| `-Action` | string | Status | Status, Enable, or Scavenge |
| `-NoRefreshInterval` | timespan | 7 days | No-refresh interval |
| `-RefreshInterval` | timespan | 7 days | Refresh interval |

**Example:**
```powershell
# Check current scavenging settings
.\Start-DNSScavenging.ps1 -Action Status

# Enable scavenging on all zones
.\Start-DNSScavenging.ps1 -Action Enable

# Manually trigger scavenging
.\Start-DNSScavenging.ps1 -Action Scavenge
```

**Note:** Scavenging removes DNS records that haven't been refreshed within the configured intervals. This helps clean up records for decommissioned machines.
