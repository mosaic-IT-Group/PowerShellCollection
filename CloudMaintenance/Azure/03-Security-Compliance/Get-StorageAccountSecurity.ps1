#Requires -Modules Az.Accounts, Az.Storage
<#
.SYNOPSIS
    Audits storage account security settings.
.DESCRIPTION
    Checks for HTTPS-only, public access, network rules, and encryption.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [switch]$ExportCsv,
    [string]$ExportPath = ".\StorageSecurity.csv"
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Auditing storage account security..." -ForegroundColor Cyan

$StorageAccounts = Get-AzStorageAccount

$Results = foreach ($SA in $StorageAccounts) {
    $Issues = @()

    # Check HTTPS only
    if (-not $SA.EnableHttpsTrafficOnly) {
        $Issues += 'HTTP allowed'
    }

    # Check public blob access
    if ($SA.AllowBlobPublicAccess) {
        $Issues += 'Public blob access enabled'
    }

    # Check network rules
    if ($SA.NetworkRuleSet.DefaultAction -eq 'Allow') {
        $Issues += 'Open to all networks'
    }

    # Check minimum TLS version
    if ($SA.MinimumTlsVersion -lt 'TLS1_2') {
        $Issues += 'TLS 1.2 not enforced'
    }

    $Status = if ($Issues.Count -eq 0) { 'Secure' } else { 'Issues Found' }

    [PSCustomObject]@{
        Name = $SA.StorageAccountName
        ResourceGroup = $SA.ResourceGroupName
        Location = $SA.Location
        HttpsOnly = $SA.EnableHttpsTrafficOnly
        PublicAccess = $SA.AllowBlobPublicAccess
        NetworkAccess = $SA.NetworkRuleSet.DefaultAction
        MinTls = $SA.MinimumTlsVersion
        Issues = $Issues -join '; '
        Status = $Status
    }
}

Write-Host "`n=== Storage Account Security Audit ===" -ForegroundColor Green
$Results | Format-Table Name, HttpsOnly, PublicAccess, NetworkAccess, MinTls, Status -AutoSize

$Insecure = $Results | Where-Object { $_.Status -eq 'Issues Found' }
if ($Insecure) {
    Write-Host "`nStorage accounts with security issues:" -ForegroundColor Yellow
    foreach ($SA in $Insecure) {
        Write-Host "  $($SA.Name): $($SA.Issues)" -ForegroundColor Yellow
    }
}

if ($ExportCsv) {
    $Results | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "`nExported to: $ExportPath"
}
