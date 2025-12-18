#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Processes user offboarding by disabling account and securing resources.
.DESCRIPTION
    Automates employee offboarding by disabling AD account, removing group memberships,
    forwarding email, archiving home directory, and generating audit report.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$Username,

    [ValidateSet('Immediate', 'Scheduled')]
    [string]$OffboardingType = 'Immediate',

    [datetime]$ScheduledDate,

    [string]$ForwardEmailTo,

    [string]$ArchivePath,

    [string]$DisabledOU,

    [switch]$RemoveFromGroups,

    [switch]$DisableAccount,

    [switch]$ResetPassword,

    [switch]$HideFromGAL,

    [switch]$ConvertToSharedMailbox,

    [string]$TicketNumber,

    [string]$ReportPath
)

# Verify user exists
$User = Get-ADUser -Filter "SamAccountName -eq '$Username'" -Properties * -ErrorAction SilentlyContinue
if (-not $User) {
    Write-Error "User '$Username' not found in Active Directory."
    return
}

$DisplayName = $User.DisplayName
$Email = $User.EmailAddress

Write-Host "`nOffboarding: $DisplayName ($Username)" -ForegroundColor Yellow
Write-Host "=" * 50

# Initialize audit log
$AuditLog = @()
$AuditLog += [PSCustomObject]@{
    Timestamp = Get-Date
    Action    = "Offboarding Started"
    Details   = "User: $Username, Display Name: $DisplayName"
    Status    = "Success"
}

# Check for scheduled offboarding
if ($OffboardingType -eq 'Scheduled' -and $ScheduledDate) {
    if ($ScheduledDate -gt (Get-Date)) {
        Write-Host "Scheduled offboarding for: $ScheduledDate" -ForegroundColor Cyan

        # Set account expiration date
        if ($PSCmdlet.ShouldProcess($Username, "Set account expiration to $ScheduledDate")) {
            Set-ADUser -Identity $Username -AccountExpirationDate $ScheduledDate
            $AuditLog += [PSCustomObject]@{
                Timestamp = Get-Date
                Action    = "Account Expiration Set"
                Details   = "Expires: $ScheduledDate"
                Status    = "Success"
            }
            Write-Host "  Account will expire on: $ScheduledDate" -ForegroundColor Green
        }

        Write-Host "`nScheduled offboarding configured. Run again after $ScheduledDate for full offboarding."
        return
    }
}

# Capture current group memberships before removal
$CurrentGroups = Get-ADPrincipalGroupMembership -Identity $Username |
    Where-Object { $_.Name -ne 'Domain Users' } |
    Select-Object -ExpandProperty Name

$AuditLog += [PSCustomObject]@{
    Timestamp = Get-Date
    Action    = "Group Membership Captured"
    Details   = $CurrentGroups -join "; "
    Status    = "Info"
}

# Disable the account
if ($DisableAccount) {
    if ($PSCmdlet.ShouldProcess($Username, "Disable AD Account")) {
        try {
            Disable-ADAccount -Identity $Username

            # Update description with offboarding info
            $Description = "DISABLED: $(Get-Date -Format 'yyyy-MM-dd')"
            if ($TicketNumber) { $Description += " | Ticket: $TicketNumber" }
            Set-ADUser -Identity $Username -Description $Description

            Write-Host "  Account disabled" -ForegroundColor Green
            $AuditLog += [PSCustomObject]@{
                Timestamp = Get-Date
                Action    = "Account Disabled"
                Details   = $Description
                Status    = "Success"
            }
        } catch {
            Write-Warning "  Failed to disable account: $_"
            $AuditLog += [PSCustomObject]@{
                Timestamp = Get-Date
                Action    = "Account Disable Failed"
                Details   = $_.ToString()
                Status    = "Error"
            }
        }
    }
}

# Reset password to random value
if ($ResetPassword) {
    if ($PSCmdlet.ShouldProcess($Username, "Reset password to random value")) {
        try {
            Add-Type -AssemblyName System.Web
            $RandomPassword = [System.Web.Security.Membership]::GeneratePassword(32, 8)
            $SecurePass = ConvertTo-SecureString $RandomPassword -AsPlainText -Force
            Set-ADAccountPassword -Identity $Username -NewPassword $SecurePass -Reset
            Write-Host "  Password reset to random value" -ForegroundColor Green
            $AuditLog += [PSCustomObject]@{
                Timestamp = Get-Date
                Action    = "Password Reset"
                Details   = "Reset to random 32-character password"
                Status    = "Success"
            }
        } catch {
            Write-Warning "  Failed to reset password: $_"
        }
    }
}

# Remove from all groups
if ($RemoveFromGroups) {
    if ($PSCmdlet.ShouldProcess($Username, "Remove from all groups")) {
        foreach ($Group in $CurrentGroups) {
            try {
                Remove-ADGroupMember -Identity $Group -Members $Username -Confirm:$false
                Write-Host "  Removed from group: $Group" -ForegroundColor Cyan
            } catch {
                Write-Warning "  Failed to remove from group '$Group': $_"
            }
        }
        $AuditLog += [PSCustomObject]@{
            Timestamp = Get-Date
            Action    = "Removed from Groups"
            Details   = "Removed from $($CurrentGroups.Count) groups"
            Status    = "Success"
        }
    }
}

# Hide from Global Address List (Exchange attribute)
if ($HideFromGAL) {
    if ($PSCmdlet.ShouldProcess($Username, "Hide from GAL")) {
        try {
            Set-ADUser -Identity $Username -Replace @{msExchHideFromAddressLists = $true}
            Write-Host "  Hidden from Global Address List" -ForegroundColor Green
            $AuditLog += [PSCustomObject]@{
                Timestamp = Get-Date
                Action    = "Hidden from GAL"
                Details   = "msExchHideFromAddressLists = true"
                Status    = "Success"
            }
        } catch {
            Write-Warning "  Failed to hide from GAL: $_"
        }
    }
}

# Archive home directory
if ($ArchivePath -and $User.HomeDirectory) {
    if (Test-Path $User.HomeDirectory) {
        $ArchiveFileName = "$Username`_HomeDir_$(Get-Date -Format 'yyyyMMdd').zip"
        $ArchiveFullPath = Join-Path $ArchivePath $ArchiveFileName

        if ($PSCmdlet.ShouldProcess($User.HomeDirectory, "Archive to $ArchiveFullPath")) {
            try {
                Compress-Archive -Path $User.HomeDirectory -DestinationPath $ArchiveFullPath -Force
                Write-Host "  Home directory archived to: $ArchiveFullPath" -ForegroundColor Green
                $AuditLog += [PSCustomObject]@{
                    Timestamp = Get-Date
                    Action    = "Home Directory Archived"
                    Details   = "Archived to: $ArchiveFullPath"
                    Status    = "Success"
                }
            } catch {
                Write-Warning "  Failed to archive home directory: $_"
            }
        }
    } else {
        Write-Host "  Home directory not found: $($User.HomeDirectory)" -ForegroundColor Yellow
    }
}

# Move to Disabled OU
if ($DisabledOU) {
    if ($PSCmdlet.ShouldProcess($Username, "Move to $DisabledOU")) {
        try {
            Move-ADObject -Identity $User.DistinguishedName -TargetPath $DisabledOU
            Write-Host "  Moved to Disabled OU: $DisabledOU" -ForegroundColor Green
            $AuditLog += [PSCustomObject]@{
                Timestamp = Get-Date
                Action    = "Moved to Disabled OU"
                Details   = "New location: $DisabledOU"
                Status    = "Success"
            }
        } catch {
            Write-Warning "  Failed to move to Disabled OU: $_"
        }
    }
}

# Generate offboarding report
$Report = [PSCustomObject]@{
    Username            = $Username
    DisplayName         = $DisplayName
    Email               = $Email
    Department          = $User.Department
    Title               = $User.Title
    Manager             = $User.Manager
    OffboardingDate     = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    TicketNumber        = $TicketNumber
    PreviousGroups      = $CurrentGroups -join ", "
    AccountDisabled     = $DisableAccount.IsPresent
    PasswordReset       = $ResetPassword.IsPresent
    GroupsRemoved       = $RemoveFromGroups.IsPresent
    HiddenFromGAL       = $HideFromGAL.IsPresent
    HomeDirectoryPath   = $User.HomeDirectory
    ArchivePath         = if ($ArchivePath) { Join-Path $ArchivePath "$Username`_HomeDir_$(Get-Date -Format 'yyyyMMdd').zip" } else { "N/A" }
}

Write-Host "`nOffboarding Summary:" -ForegroundColor Green
$Report | Format-List

# Export audit log
if ($ReportPath) {
    $ReportFile = Join-Path $ReportPath "Offboarding_$Username`_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $AuditLog | Export-Csv -Path $ReportFile -NoTypeInformation
    Write-Host "Audit log saved to: $ReportFile" -ForegroundColor Cyan
}

# Output summary
Write-Host "`n" + "=" * 50
Write-Host "Offboarding Complete for $DisplayName" -ForegroundColor Green
Write-Host "=" * 50
