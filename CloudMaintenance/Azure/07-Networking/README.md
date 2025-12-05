# Networking

Scripts for Azure network monitoring and security.

## Scripts

### Get-NSGRules.ps1

Audits Network Security Group rules for security risks.

**Risk Levels:**
- **Critical:** Allow all ports from any source (inbound)
- **High:** Allow SSH/RDP/SMB from any source
- **Medium:** Allow any port from any source
- **Low:** Restricted rules

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-ResourceGroupName` | string | all | Filter by resource group |
| `-OpenRulesOnly` | switch | false | Show only risky rules |
| `-ExportCsv` | switch | false | Export results to CSV |

**Example:**
```powershell
.\Get-NSGRules.ps1 -OpenRulesOnly
```

**Output:**
```
=== NSG Rules Audit ===
Total Rules: 45
Critical: 2
High: 5
Medium: 8
Low: 30

CRITICAL: Rules allowing all ports from any source:
NSG           RuleName          SourceAddress  DestPort
---           --------          -------------  --------
nsg-legacy    AllowAll          *              *
nsg-test      AllowAny          Internet       *
```

---

### Get-PublicIPs.ps1

Lists public IP addresses and their associations.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-UnassignedOnly` | switch | false | Show only unassigned IPs |

**Example:**
```powershell
.\Get-PublicIPs.ps1 -UnassignedOnly
```

**Output:**
```
=== Public IP Addresses ===
Total: 12
Assigned: 10
Unassigned: 2

Unassigned IPs (potential monthly savings: ~$7.30):
Name          ResourceGroup  IPAddress
----          -------------  ---------
pip-old-web   rg-legacy      52.168.1.100
pip-test      rg-test        52.168.1.101
```

---

### Get-VNetPeerings.ps1

Lists VNet peering connections and their status.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-DisconnectedOnly` | switch | false | Show only disconnected peerings |

**Example:**
```powershell
.\Get-VNetPeerings.ps1
```

**States:**
- **Connected:** Peering is healthy
- **Disconnected:** Peering requires attention (may indicate deleted remote VNet)

---

### Test-Connectivity.ps1

Tests network connectivity between Azure resources using Network Watcher.

**Requirements:**
- Network Watcher enabled in the region
- Network Watcher extension on source VM

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SourceVMName` | string | (required) | Source VM name |
| `-SourceResourceGroup` | string | (required) | Source VM resource group |
| `-DestinationVMName` | string | - | Destination VM (if Azure VM) |
| `-DestinationResourceGroup` | string | - | Destination VM resource group |
| `-DestinationAddress` | string | - | Destination IP/FQDN (if external) |
| `-DestinationPort` | int | 443 | Port to test |
| `-Protocol` | string | TCP | TCP or ICMP |

**Example:**
```powershell
# Test VM to VM connectivity
.\Test-Connectivity.ps1 -SourceVMName "vm-web" -SourceResourceGroup "rg-prod" `
    -DestinationVMName "vm-db" -DestinationResourceGroup "rg-prod" -DestinationPort 1433

# Test VM to external endpoint
.\Test-Connectivity.ps1 -SourceVMName "vm-web" -SourceResourceGroup "rg-prod" `
    -DestinationAddress "api.example.com" -DestinationPort 443
```
