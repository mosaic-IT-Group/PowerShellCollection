# Networking

Scripts for network infrastructure monitoring and maintenance.

## Scripts

### Get-DHCPScopeStatus.ps1

Monitors DHCP scope utilization and alerts on low availability.

**Requirements:**
- DhcpServer PowerShell module
- DHCP Server role or RSAT tools

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-DhcpServer` | string | localhost | DHCP server name |
| `-WarningThreshold` | int | 80 | Usage percentage for warning |

**Example:**
```powershell
# Check local DHCP server
.\Get-DHCPScopeStatus.ps1

# Check remote server with custom threshold
.\Get-DHCPScopeStatus.ps1 -DhcpServer "DHCP01" -WarningThreshold 70
```

**Output:**
```
ScopeId        Name           State   TotalAddresses  InUse  Free  Used%  Status
-------        ----           -----   --------------  -----  ----  -----  ------
192.168.1.0    Office LAN     Active  200             180    20    90.00  WARNING
192.168.2.0    Guest Network  Active  50              10     40    20.00  OK
```

---

### Clear-DNSCache.ps1

Flushes DNS resolver cache on local or remote computers.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-ComputerName` | string[] | localhost | Target computers |
| `-IncludeServerCache` | switch | false | Also clear DNS Server cache |

**Example:**
```powershell
# Clear local DNS cache
.\Clear-DNSCache.ps1

# Clear cache on multiple computers
.\Clear-DNSCache.ps1 -ComputerName "PC01", "PC02"

# Clear both client and server cache
.\Clear-DNSCache.ps1 -IncludeServerCache
```

**Use Cases:**
- After DNS changes to force re-resolution
- Troubleshooting DNS resolution issues
- After malware cleanup

---

### Get-NetworkSharePermissions.ps1

Audits SMB share permissions for security review.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-ComputerName` | string | localhost | Target computer |
| `-IncludeAdminShares` | switch | false | Include C$, ADMIN$, etc. |

**Example:**
```powershell
# Audit shares on file server
.\Get-NetworkSharePermissions.ps1 -ComputerName "FILESERVER01"
```

**Output:**
```
Share: Data
  Path: D:\Data
  Description: Company shared data
  Permissions:
    [F] DOMAIN\Admins - Allow
    [C] DOMAIN\Users - Allow
    [R] Everyone - Allow
```

**Security Alert:** Warns if any shares have "Everyone - Full" access.

---

### Test-NetworkConnectivity.ps1

Tests network connectivity to critical endpoints via ping and port checks.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Targets` | hashtable | (defaults) | Endpoints to test |
| `-TimeoutSeconds` | int | 5 | Connection timeout |

**Default Targets:**
- Google DNS (8.8.8.8:53)
- Microsoft (www.microsoft.com:443)
- Domain Controller (LDAP port 389)

**Example:**
```powershell
# Test default targets
.\Test-NetworkConnectivity.ps1

# Custom targets
$Targets = @{
    'SQL Server' = @{ Host = 'sql01.domain.com'; Port = 1433 }
    'Web App' = @{ Host = 'webapp.domain.com'; Port = 443 }
}
.\Test-NetworkConnectivity.ps1 -Targets $Targets
```

**Output:**
```
Name              Host              Port  Ping  PortOpen  Latency  Status
----              ----              ----  ----  --------  -------  ------
Google DNS        8.8.8.8           53    True  True      15ms     Connected
Microsoft         www.microsoft.com 443   True  True      23ms     Connected
Domain Controller DC01              389   True  True      2ms      Connected
```
