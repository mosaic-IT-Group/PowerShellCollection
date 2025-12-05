#Requires -Modules Az.Accounts, Az.KeyVault
<#
.SYNOPSIS
    Audits Key Vault secrets for expiration.
.DESCRIPTION
    Lists secrets, keys, and certificates with expiration dates.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$VaultName,
    [int]$ExpiringWithinDays = 30
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

Write-Host "Auditing Key Vault: $VaultName" -ForegroundColor Cyan

$ExpiryDate = (Get-Date).AddDays($ExpiringWithinDays)

# Secrets
Write-Host "`nSecrets:"
$Secrets = Get-AzKeyVaultSecret -VaultName $VaultName

$SecretResults = foreach ($Secret in $Secrets) {
    $Status = if (-not $Secret.Expires) {
        'No Expiry'
    } elseif ($Secret.Expires -lt (Get-Date)) {
        'EXPIRED'
    } elseif ($Secret.Expires -lt $ExpiryDate) {
        'Expiring Soon'
    } else {
        'OK'
    }

    [PSCustomObject]@{
        Type = 'Secret'
        Name = $Secret.Name
        Enabled = $Secret.Enabled
        Expires = $Secret.Expires
        Status = $Status
    }
}

# Keys
Write-Host "Keys:"
$Keys = Get-AzKeyVaultKey -VaultName $VaultName

$KeyResults = foreach ($Key in $Keys) {
    $Status = if (-not $Key.Expires) {
        'No Expiry'
    } elseif ($Key.Expires -lt (Get-Date)) {
        'EXPIRED'
    } elseif ($Key.Expires -lt $ExpiryDate) {
        'Expiring Soon'
    } else {
        'OK'
    }

    [PSCustomObject]@{
        Type = 'Key'
        Name = $Key.Name
        Enabled = $Key.Enabled
        Expires = $Key.Expires
        Status = $Status
    }
}

# Certificates
Write-Host "Certificates:"
$Certs = Get-AzKeyVaultCertificate -VaultName $VaultName

$CertResults = foreach ($Cert in $Certs) {
    $Status = if ($Cert.Expires -lt (Get-Date)) {
        'EXPIRED'
    } elseif ($Cert.Expires -lt $ExpiryDate) {
        'Expiring Soon'
    } else {
        'OK'
    }

    [PSCustomObject]@{
        Type = 'Certificate'
        Name = $Cert.Name
        Enabled = $Cert.Enabled
        Expires = $Cert.Expires
        Status = $Status
    }
}

$AllResults = $SecretResults + $KeyResults + $CertResults

Write-Host "`n=== Key Vault Audit Report ===" -ForegroundColor Green
$AllResults | Format-Table Type, Name, Enabled, Expires, Status -AutoSize

$Issues = $AllResults | Where-Object { $_.Status -in @('EXPIRED', 'Expiring Soon') }
if ($Issues) {
    Write-Host "`nItems requiring attention:" -ForegroundColor Yellow
    $Issues | Format-Table -AutoSize
}
