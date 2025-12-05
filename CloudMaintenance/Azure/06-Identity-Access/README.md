# Identity & Access

Scripts for Azure RBAC and identity management.

## Scripts

### Get-RoleAssignments.ps1

Audits Azure RBAC role assignments.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-ResourceGroupName` | string | all | Filter by resource group |
| `-PrincipalType` | string | All | All, User, Group, or ServicePrincipal |
| `-ExportCsv` | switch | false | Export results to CSV |

**Example:**
```powershell
# Get service principal assignments
.\Get-RoleAssignments.ps1 -PrincipalType ServicePrincipal
```

**Security Alerts:**
- High-privilege roles (Owner, Contributor) at subscription level
- Excessive role assignments

---

### Get-ServicePrincipals.ps1

Audits service principals and their credential expiration.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-ExpiringWithinDays` | int | 30 | Alert threshold for expiring credentials |
| `-ExpiringOnly` | switch | false | Show only expiring/expired |
| `-ExportCsv` | switch | false | Export results to CSV |

**Example:**
```powershell
.\Get-ServicePrincipals.ps1 -ExpiringWithinDays 60
```

**Output:**
```
=== Service Principal Audit ===
Total: 15
EXPIRED: 2
Expiring Soon: 3
OK: 10

DisplayName        Roles                      CredentialStatus  NextExpiry
-----------        -----                      ----------------  ----------
sp-deploy-prod     Contributor                OK                2025-06-15
sp-backup          Backup Contributor         Expiring Soon     2024-12-20
sp-legacy          Reader                     EXPIRED           2024-11-01
```

---

### Get-ManagedIdentities.ps1

Lists managed identities and their role assignments.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-IdentityType` | string | All | All, SystemAssigned, or UserAssigned |

**Example:**
```powershell
.\Get-ManagedIdentities.ps1 -IdentityType UserAssigned
```

**Checks:**
- User-assigned managed identities
- System-assigned identities on VMs
- System-assigned identities on App Services
- Identities without role assignments

---

### Get-GuestUsers.ps1

Identifies external/guest users with Azure access.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-ExportCsv` | switch | false | Export results to CSV |

**Example:**
```powershell
.\Get-GuestUsers.ps1
```

**Security Alerts:**
- Guests with Owner role
- Guests with Contributor role
- Guests with User Access Administrator role

**Best Practice:** Regularly review guest access and remove unnecessary permissions.
