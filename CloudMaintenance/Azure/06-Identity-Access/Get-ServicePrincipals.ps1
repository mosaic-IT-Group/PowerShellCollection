#Requires -Modules Az.Accounts, Az.Resources
<#
.SYNOPSIS
    Audits Azure AD service principals and their credentials.
.DESCRIPTION
    Lists service principals, their expiring credentials, and permissions.
#>

[CmdletBinding()]
param(
    [int]$ExpiringWithinDays = 30,
    [switch]$ExpiringOnly,
    [switch]$ExportCsv,
    [string]$ExportPath = ".\ServicePrincipals.csv"
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

Write-Host "Retrieving service principals..." -ForegroundColor Cyan

$ExpiryDate = (Get-Date).AddDays($ExpiringWithinDays)

# Get service principals with role assignments
$RoleAssignments = Get-AzRoleAssignment | Where-Object { $_.ObjectType -eq 'ServicePrincipal' }

$SPNs = $RoleAssignments | Select-Object -Unique ObjectId, DisplayName

$Results = foreach ($SPN in $SPNs) {
    # Get credentials
    try {
        $App = Get-AzADApplication -DisplayName $SPN.DisplayName -ErrorAction SilentlyContinue
        $Credentials = if ($App) {
            Get-AzADAppCredential -ObjectId $App.Id -ErrorAction SilentlyContinue
        }
    } catch {
        $Credentials = $null
    }

    $ExpiringCreds = if ($Credentials) {
        $Credentials | Where-Object { $_.EndDateTime -lt $ExpiryDate -and $_.EndDateTime -gt (Get-Date) }
    }

    $ExpiredCreds = if ($Credentials) {
        $Credentials | Where-Object { $_.EndDateTime -lt (Get-Date) }
    }

    $CredStatus = if ($ExpiredCreds) {
        'EXPIRED'
    } elseif ($ExpiringCreds) {
        'Expiring Soon'
    } elseif ($Credentials) {
        'OK'
    } else {
        'No Credentials'
    }

    # Get roles
    $Roles = $RoleAssignments | Where-Object { $_.ObjectId -eq $SPN.ObjectId } |
        Select-Object -ExpandProperty RoleDefinitionName -Unique

    [PSCustomObject]@{
        DisplayName = $SPN.DisplayName
        ObjectId = $SPN.ObjectId
        Roles = $Roles -join ', '
        CredentialStatus = $CredStatus
        NextExpiry = if ($Credentials) { ($Credentials.EndDateTime | Sort-Object | Select-Object -First 1) } else { 'N/A' }
    }
}

if ($ExpiringOnly) {
    $Results = $Results | Where-Object { $_.CredentialStatus -in @('EXPIRED', 'Expiring Soon') }
}

Write-Host "`n=== Service Principal Audit ===" -ForegroundColor Green
Write-Host "Total: $($Results.Count)"

# Summary by status
$Results | Group-Object CredentialStatus | ForEach-Object {
    $Color = switch ($_.Name) {
        'EXPIRED' { 'Red' }
        'Expiring Soon' { 'Yellow' }
        'OK' { 'Green' }
        default { 'White' }
    }
    Write-Host "$($_.Name): $($_.Count)" -ForegroundColor $Color
}

Write-Host ""
$Results | Format-Table DisplayName, Roles, CredentialStatus, NextExpiry -AutoSize

if ($ExportCsv) {
    $Results | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Exported to: $ExportPath"
}
