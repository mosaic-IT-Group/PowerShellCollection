<#
.SYNOPSIS
    Checks for certificates that are expiring soon.
.DESCRIPTION
    Scans local machine certificate stores for certificates expiring within specified days.
#>

[CmdletBinding()]
param(
    [int]$DaysUntilExpiry = 30
)

$ExpiryDate = (Get-Date).AddDays($DaysUntilExpiry)

$Stores = @('My', 'WebHosting', 'Root', 'CA')

$ExpiringCerts = foreach ($StoreName in $Stores) {
    $Store = Get-ChildItem -Path "Cert:\LocalMachine\$StoreName" -ErrorAction SilentlyContinue

    $Store | Where-Object {
        $_.NotAfter -lt $ExpiryDate -and $_.NotAfter -gt (Get-Date)
    } | Select-Object @{N='Store';E={$StoreName}},
        Subject,
        Thumbprint,
        NotAfter,
        @{N='DaysRemaining';E={($_.NotAfter - (Get-Date)).Days}}
}

if ($ExpiringCerts) {
    Write-Warning "Certificates expiring within $DaysUntilExpiry days:"
    $ExpiringCerts | Format-Table -AutoSize
}
else {
    Write-Host "No certificates expiring within $DaysUntilExpiry days."
}
