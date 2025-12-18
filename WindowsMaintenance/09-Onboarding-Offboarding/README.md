# Onboarding & Offboarding

Scripts for automating user provisioning and deprovisioning workflows.

## Requirements

- Active Directory PowerShell module
- Domain Admin or delegated permissions for user management
- Run from a domain-joined machine

## Scripts

### New-UserOnboarding.ps1

Creates a new AD user account with standard onboarding configuration.

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-FirstName` | string | Yes | User's first name |
| `-LastName` | string | Yes | User's last name |
| `-Department` | string | Yes | Department name |
| `-JobTitle` | string | Yes | Job title |
| `-TargetOU` | string | Yes | OU path for new user |
| `-Manager` | string | No | Manager's username or display name |
| `-HomeDirectoryPath` | string | No | Base path for home directories |
| `-Groups` | string[] | No | Additional groups to add user to |
| `-TemplateName` | string | No | Copy group memberships from template user |
| `-SendWelcomeEmail` | switch | No | Send welcome email with credentials |
| `-EmailServer` | string | No | SMTP server for welcome email |
| `-GeneratePassword` | switch | No | Auto-generate secure password |

**Example:**
```powershell
# Basic user creation
.\New-UserOnboarding.ps1 -FirstName "John" -LastName "Smith" -Department "Sales" `
    -JobTitle "Sales Representative" -TargetOU "OU=Users,DC=contoso,DC=com"

# Full onboarding with template and home directory
.\New-UserOnboarding.ps1 -FirstName "Jane" -LastName "Doe" -Department "IT" `
    -JobTitle "Systems Administrator" -TargetOU "OU=IT,OU=Users,DC=contoso,DC=com" `
    -Manager "jmanager" -TemplateName "template.it" `
    -HomeDirectoryPath "\\fileserver\homes" -GeneratePassword

# With welcome email
.\New-UserOnboarding.ps1 -FirstName "Bob" -LastName "Wilson" -Department "HR" `
    -JobTitle "HR Coordinator" -TargetOU "OU=HR,OU=Users,DC=contoso,DC=com" `
    -Groups "HR-Team", "AllStaff" -SendWelcomeEmail -EmailServer "smtp.contoso.com" `
    -GeneratePassword
```

**Features:**
- Generates username from first initial + last name
- Handles duplicate usernames automatically
- Copies group memberships from template users
- Creates and permissions home directories
- Sends welcome email with credentials

---

### Start-UserOffboarding.ps1

Processes user offboarding by disabling account and securing resources.

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Username` | string | Yes | User's SAM account name |
| `-OffboardingType` | string | No | Immediate or Scheduled (default: Immediate) |
| `-ScheduledDate` | datetime | No | Future date for scheduled offboarding |
| `-ForwardEmailTo` | string | No | Email address to forward mail to |
| `-ArchivePath` | string | No | Path to archive home directory |
| `-DisabledOU` | string | No | OU to move disabled account to |
| `-RemoveFromGroups` | switch | No | Remove from all security groups |
| `-DisableAccount` | switch | No | Disable the AD account |
| `-ResetPassword` | switch | No | Reset password to random value |
| `-HideFromGAL` | switch | No | Hide from Exchange Global Address List |
| `-ConvertToSharedMailbox` | switch | No | Convert mailbox to shared |
| `-TicketNumber` | string | No | Help desk ticket reference |
| `-ReportPath` | string | No | Path to save audit report |

**Example:**
```powershell
# Immediate full offboarding
.\Start-UserOffboarding.ps1 -Username "jsmith" -DisableAccount -ResetPassword `
    -RemoveFromGroups -HideFromGAL -DisabledOU "OU=Disabled,DC=contoso,DC=com" `
    -ArchivePath "\\fileserver\archives" -TicketNumber "INC001234" `
    -ReportPath "C:\Reports"

# Scheduled offboarding (account expires on date)
.\Start-UserOffboarding.ps1 -Username "jdoe" -OffboardingType Scheduled `
    -ScheduledDate "2024-03-15"

# Basic disable and move
.\Start-UserOffboarding.ps1 -Username "bwilson" -DisableAccount `
    -DisabledOU "OU=Disabled,DC=contoso,DC=com"

# Preview changes without applying
.\Start-UserOffboarding.ps1 -Username "mgarcia" -DisableAccount -RemoveFromGroups -WhatIf
```

**Features:**
- Captures group memberships before removal (for audit)
- Supports scheduled offboarding with account expiration
- Archives home directory to ZIP file
- Generates detailed audit log
- Updates account description with offboarding date and ticket
- Resets password to random 32-character string

---

## Best Practices

### Onboarding
1. Create template users for each department/role with standard group memberships
2. Use `-WhatIf` to preview changes before creating accounts
3. Always use `-GeneratePassword` for secure initial passwords
4. Store welcome email credentials securely or deliver in person

### Offboarding
1. Always capture group memberships before removal (script does this automatically)
2. Use scheduled offboarding for known departure dates
3. Archive home directories before deletion
4. Keep disabled accounts for 90+ days before deletion for compliance
5. Generate and retain audit reports for HR/compliance

### Scheduling
```powershell
# Daily check for scheduled offboardings
$Action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File C:\Scripts\Process-ScheduledOffboardings.ps1"
$Trigger = New-ScheduledTaskTrigger -Daily -At "6:00 AM"
Register-ScheduledTask -TaskName "Process Offboardings" -Action $Action -Trigger $Trigger
```
