#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Identifies and removes stale AD computer and user accounts.
.DESCRIPTION
    Finds accounts that haven't logged in within specified days and optionally disables/removes them.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [int]$InactiveDays = 90,

    [ValidateSet('Computers', 'Users', 'Both')]
    [string]$ObjectType = 'Both',

    [ValidateSet('Report', 'Disable', 'Delete')]
    [string]$Action = 'Report',

    [string]$ExcludeOU
)

$CutoffDate = (Get-Date).AddDays(-$InactiveDays)

$Results = @()

# Stale Computers
if ($ObjectType -in @('Computers', 'Both')) {
    $Filter = { LastLogonDate -lt $CutoffDate -and Enabled -eq $true }

    $StaleComputers = Get-ADComputer -Filter $Filter -Properties LastLogonDate, DistinguishedName |
        Where-Object { -not $ExcludeOU -or $_.DistinguishedName -notlike "*$ExcludeOU*" }

    foreach ($Computer in $StaleComputers) {
        $Results += [PSCustomObject]@{
            Type = 'Computer'
            Name = $Computer.Name
            LastLogon = $Computer.LastLogonDate
            DN = $Computer.DistinguishedName
        }

        if ($Action -eq 'Disable' -and $PSCmdlet.ShouldProcess($Computer.Name, "Disable")) {
            Disable-ADAccount -Identity $Computer
        }
        elseif ($Action -eq 'Delete' -and $PSCmdlet.ShouldProcess($Computer.Name, "Delete")) {
            Remove-ADComputer -Identity $Computer -Confirm:$false
        }
    }
}

# Stale Users
if ($ObjectType -in @('Users', 'Both')) {
    $Filter = { LastLogonDate -lt $CutoffDate -and Enabled -eq $true }

    $StaleUsers = Get-ADUser -Filter $Filter -Properties LastLogonDate, DistinguishedName |
        Where-Object { -not $ExcludeOU -or $_.DistinguishedName -notlike "*$ExcludeOU*" }

    foreach ($User in $StaleUsers) {
        $Results += [PSCustomObject]@{
            Type = 'User'
            Name = $User.SamAccountName
            LastLogon = $User.LastLogonDate
            DN = $User.DistinguishedName
        }

        if ($Action -eq 'Disable' -and $PSCmdlet.ShouldProcess($User.SamAccountName, "Disable")) {
            Disable-ADAccount -Identity $User
        }
        elseif ($Action -eq 'Delete' -and $PSCmdlet.ShouldProcess($User.SamAccountName, "Delete")) {
            Remove-ADUser -Identity $User -Confirm:$false
        }
    }
}

Write-Host "`nStale Objects Report (Inactive > $InactiveDays days):"
$Results | Format-Table -AutoSize

Write-Host "Total: $($Results.Count) stale objects found."
