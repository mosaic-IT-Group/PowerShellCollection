<#
.SYNOPSIS
    Audits network share permissions.
.DESCRIPTION
    Lists all SMB shares and their permissions for security review.
#>

[CmdletBinding()]
param(
    [string]$ComputerName = $env:COMPUTERNAME,
    [switch]$IncludeAdminShares
)

Write-Host "Network Share Audit for: $ComputerName`n"

$Shares = Get-SmbShare -CimSession $ComputerName -ErrorAction Stop

if (-not $IncludeAdminShares) {
    $Shares = $Shares | Where-Object { $_.Name -notmatch '^\w\$|^ADMIN\$|^IPC\$' }
}

foreach ($Share in $Shares) {
    Write-Host "Share: $($Share.Name)" -ForegroundColor Cyan
    Write-Host "  Path: $($Share.Path)"
    Write-Host "  Description: $($Share.Description)"

    $Access = Get-SmbShareAccess -Name $Share.Name -CimSession $ComputerName

    Write-Host "  Permissions:"
    foreach ($Ace in $Access) {
        $Icon = switch ($Ace.AccessRight) {
            'Full'   { '[F]' }
            'Change' { '[C]' }
            'Read'   { '[R]' }
            default  { '[?]' }
        }
        Write-Host "    $Icon $($Ace.AccountName) - $($Ace.AccessControlType)"
    }
    Write-Host ""
}

# Check for Everyone with Full access
$RiskyShares = foreach ($Share in $Shares) {
    $Access = Get-SmbShareAccess -Name $Share.Name -CimSession $ComputerName
    $EveryoneFull = $Access | Where-Object {
        $_.AccountName -eq 'Everyone' -and $_.AccessRight -eq 'Full'
    }
    if ($EveryoneFull) { $Share.Name }
}

if ($RiskyShares) {
    Write-Warning "Shares with 'Everyone - Full' access:"
    $RiskyShares | ForEach-Object { Write-Warning "  - $_" }
}
