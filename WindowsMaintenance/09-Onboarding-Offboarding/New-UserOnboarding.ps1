#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Creates a new AD user account with standard onboarding configuration.
.DESCRIPTION
    Automates new employee onboarding by creating AD account, setting up group memberships,
    creating home directory, and optionally sending welcome email.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$FirstName,

    [Parameter(Mandatory)]
    [string]$LastName,

    [Parameter(Mandatory)]
    [string]$Department,

    [Parameter(Mandatory)]
    [string]$JobTitle,

    [string]$Manager,

    [Parameter(Mandatory)]
    [string]$TargetOU,

    [string]$HomeDirectoryPath,

    [string[]]$Groups,

    [string]$TemplateName,

    [switch]$SendWelcomeEmail,

    [string]$EmailServer,

    [switch]$GeneratePassword
)

# Generate username (first initial + last name)
$Username = ($FirstName.Substring(0, 1) + $LastName).ToLower() -replace '[^a-z0-9]', ''
$DisplayName = "$FirstName $LastName"
$Email = "$Username@$((Get-ADDomain).DNSRoot)"

# Check if user already exists
if (Get-ADUser -Filter "SamAccountName -eq '$Username'" -ErrorAction SilentlyContinue) {
    Write-Warning "User '$Username' already exists. Adding number suffix."
    $Counter = 1
    while (Get-ADUser -Filter "SamAccountName -eq '$($Username + $Counter)'" -ErrorAction SilentlyContinue) {
        $Counter++
    }
    $Username = "$Username$Counter"
    $Email = "$Username@$((Get-ADDomain).DNSRoot)"
}

# Generate or prompt for password
if ($GeneratePassword) {
    Add-Type -AssemblyName System.Web
    $Password = [System.Web.Security.Membership]::GeneratePassword(16, 4)
} else {
    $SecurePassword = Read-Host -Prompt "Enter password for $Username" -AsSecureString
    $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    )
}

$SecurePass = ConvertTo-SecureString $Password -AsPlainText -Force

# Copy group memberships from template user if specified
$TemplateGroups = @()
if ($TemplateName) {
    $TemplateUser = Get-ADUser -Identity $TemplateName -Properties MemberOf -ErrorAction SilentlyContinue
    if ($TemplateUser) {
        $TemplateGroups = $TemplateUser.MemberOf | ForEach-Object { (Get-ADGroup $_).Name }
        Write-Host "Copying group memberships from template user: $TemplateName"
    } else {
        Write-Warning "Template user '$TemplateName' not found. Skipping template groups."
    }
}

# Combine template groups with explicitly specified groups
$AllGroups = @($TemplateGroups) + @($Groups) | Select-Object -Unique | Where-Object { $_ }

# Create the AD user
$UserParams = @{
    SamAccountName        = $Username
    UserPrincipalName     = $Email
    Name                  = $DisplayName
    GivenName             = $FirstName
    Surname               = $LastName
    DisplayName           = $DisplayName
    EmailAddress          = $Email
    Department            = $Department
    Title                 = $JobTitle
    Path                  = $TargetOU
    AccountPassword       = $SecurePass
    Enabled               = $true
    ChangePasswordAtLogon = $true
}

if ($Manager) {
    $ManagerUser = Get-ADUser -Filter "SamAccountName -eq '$Manager' -or DisplayName -eq '$Manager'" -ErrorAction SilentlyContinue
    if ($ManagerUser) {
        $UserParams['Manager'] = $ManagerUser.DistinguishedName
    } else {
        Write-Warning "Manager '$Manager' not found in AD."
    }
}

if ($PSCmdlet.ShouldProcess($Username, "Create AD User")) {
    try {
        New-ADUser @UserParams
        Write-Host "Created user: $Username" -ForegroundColor Green

        # Add to groups
        foreach ($Group in $AllGroups) {
            try {
                Add-ADGroupMember -Identity $Group -Members $Username
                Write-Host "  Added to group: $Group" -ForegroundColor Cyan
            } catch {
                Write-Warning "  Failed to add to group '$Group': $_"
            }
        }

        # Create home directory
        if ($HomeDirectoryPath) {
            $UserHomeDir = Join-Path $HomeDirectoryPath $Username
            if (-not (Test-Path $UserHomeDir)) {
                New-Item -Path $UserHomeDir -ItemType Directory -Force | Out-Null

                # Set permissions
                $Acl = Get-Acl $UserHomeDir
                $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    "$((Get-ADDomain).NetBIOSName)\$Username",
                    "FullControl",
                    "ContainerInherit,ObjectInherit",
                    "None",
                    "Allow"
                )
                $Acl.AddAccessRule($AccessRule)
                Set-Acl -Path $UserHomeDir -AclObject $Acl

                # Update AD user with home directory
                Set-ADUser -Identity $Username -HomeDirectory $UserHomeDir -HomeDrive "H:"
                Write-Host "  Created home directory: $UserHomeDir" -ForegroundColor Cyan
            }
        }

        # Send welcome email
        if ($SendWelcomeEmail -and $EmailServer) {
            $EmailBody = @"
Welcome to the company, $FirstName!

Your network account has been created with the following details:

Username: $Username
Email: $Email
Temporary Password: $Password

Please log in and change your password immediately.

Your manager is: $(if ($Manager) { $Manager } else { "Not assigned" })
Department: $Department

If you have any questions, please contact the IT Help Desk.

Best regards,
IT Department
"@
            try {
                Send-MailMessage -From "it@$((Get-ADDomain).DNSRoot)" `
                    -To $Email `
                    -Subject "Welcome - Your New Account Details" `
                    -Body $EmailBody `
                    -SmtpServer $EmailServer
                Write-Host "  Welcome email sent to: $Email" -ForegroundColor Cyan
            } catch {
                Write-Warning "  Failed to send welcome email: $_"
            }
        }

        # Output summary
        Write-Host "`nOnboarding Complete!" -ForegroundColor Green
        [PSCustomObject]@{
            Username      = $Username
            DisplayName   = $DisplayName
            Email         = $Email
            Department    = $Department
            Title         = $JobTitle
            Manager       = $Manager
            Groups        = $AllGroups -join ", "
            HomeDirectory = if ($HomeDirectoryPath) { Join-Path $HomeDirectoryPath $Username } else { "Not configured" }
            Password      = if ($GeneratePassword) { $Password } else { "User-specified" }
        } | Format-List

    } catch {
        Write-Error "Failed to create user '$Username': $_"
    }
}
