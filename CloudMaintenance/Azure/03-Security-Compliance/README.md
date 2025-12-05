# Security & Compliance

Scripts for security monitoring and compliance auditing.

## Scripts

### Get-SecurityRecommendations.ps1

Retrieves recommendations from Microsoft Defender for Cloud.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-Severity` | string | All | All, High, Medium, or Low |
| `-ExportCsv` | switch | false | Export results to CSV |

**Example:**
```powershell
# Get high severity recommendations only
.\Get-SecurityRecommendations.ps1 -Severity High
```

---

### Get-KeyVaultSecrets.ps1

Audits Key Vault items for expiration.

**Checks:**
- Secrets
- Keys
- Certificates

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-VaultName` | string | (required) | Key Vault name |
| `-ExpiringWithinDays` | int | 30 | Alert threshold |

**Example:**
```powershell
.\Get-KeyVaultSecrets.ps1 -VaultName "kv-prod-001" -ExpiringWithinDays 60
```

**Output:**
```
Type         Name              Enabled  Expires     Status
----         ----              -------  -------     ------
Secret       api-key           True     2024-12-15  Expiring Soon
Certificate  ssl-cert          True     2024-11-30  EXPIRED
Key          encryption-key    True     N/A         No Expiry
```

---

### Get-StorageAccountSecurity.ps1

Audits storage account security configurations.

**Checks:**
- HTTPS-only enforcement
- Public blob access
- Network access rules
- Minimum TLS version

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-ExportCsv` | switch | false | Export results to CSV |

**Example:**
```powershell
.\Get-StorageAccountSecurity.ps1
```

**Security Issues Detected:**
- HTTP allowed (should require HTTPS)
- Public blob access enabled
- Open to all networks (no firewall)
- TLS 1.2 not enforced

---

### Get-PolicyCompliance.ps1

Reports on Azure Policy compliance status.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-SubscriptionId` | string | current | Target subscription |
| `-NonCompliantOnly` | switch | false | Show only non-compliant |
| `-ExportCsv` | switch | false | Export results to CSV |

**Example:**
```powershell
.\Get-PolicyCompliance.ps1 -NonCompliantOnly
```

**Output:**
```
Compliant: 145
NonCompliant: 12

Non-Compliant Resources:
Resource          ResourceGroup  ResourceType      PolicyAssignmentName
--------          -------------  ------------      --------------------
vm-dev-01         rg-dev         VirtualMachine    Require-Tags
storage-test      rg-test        StorageAccount    Enforce-HTTPS
```
