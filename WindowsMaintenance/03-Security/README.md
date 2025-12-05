# Security

Scripts for security monitoring and maintenance.

## Scripts

### Start-MalwareScan.ps1

Initiates Windows Defender scans and reports on recent threats.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-ScanType` | string | Quick | Quick, Full, or Custom scan |
| `-CustomPath` | string | - | Path for Custom scan type |

**Example:**
```powershell
# Quick scan
.\Start-MalwareScan.ps1

# Full system scan
.\Start-MalwareScan.ps1 -ScanType Full

# Scan specific folder
.\Start-MalwareScan.ps1 -ScanType Custom -CustomPath "D:\Downloads"
```

**Behavior:**
1. Updates malware definitions
2. Runs specified scan type
3. Reports any threats detected in last 24 hours

---

### Get-SecurityAuditLogs.ps1

Analyzes Windows Security event logs for suspicious activity.

**Events Monitored:**
- 4625: Failed login attempts
- 4624: Successful logins
- 4672: Special privileges assigned (privilege escalation)

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Hours` | int | 24 | Hours of history to analyze |
| `-ExportPath` | string | - | CSV export path |

**Example:**
```powershell
# Review last 24 hours
.\Get-SecurityAuditLogs.ps1

# Export last week's data
.\Get-SecurityAuditLogs.ps1 -Hours 168 -ExportPath "C:\Reports\security.csv"
```

---

### Get-ExpiringCertificates.ps1

Scans certificate stores for certificates nearing expiration.

**Stores Checked:**
- Personal (My)
- Web Hosting
- Trusted Root
- Intermediate CA

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-DaysUntilExpiry` | int | 30 | Alert threshold in days |

**Example:**
```powershell
# Check for certs expiring in 60 days
.\Get-ExpiringCertificates.ps1 -DaysUntilExpiry 60
```

---

### Reset-LocalAdminPassword.ps1

Rotates the local Administrator account password.

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-PasswordLength` | int | 16 | Length of generated password |
| `-AdminAccount` | string | Administrator | Account name to reset |

**Example:**
```powershell
.\Reset-LocalAdminPassword.ps1 -PasswordLength 20
```

**Security Note:** For enterprise environments, use Microsoft LAPS (Local Administrator Password Solution) instead of this script for centralized, secure password management.
