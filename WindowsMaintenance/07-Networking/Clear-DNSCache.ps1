#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Clears DNS client and server cache.
.DESCRIPTION
    Flushes the DNS resolver cache on local or remote computers.
#>

[CmdletBinding()]
param(
    [string[]]$ComputerName = @($env:COMPUTERNAME),
    [switch]$IncludeServerCache
)

foreach ($Computer in $ComputerName) {
    Write-Host "Clearing DNS cache on: $Computer"

    if ($Computer -eq $env:COMPUTERNAME) {
        # Clear client cache
        Clear-DnsClientCache
        Write-Host "  DNS client cache cleared."

        # Clear server cache if requested and DNS Server role is installed
        if ($IncludeServerCache) {
            try {
                Clear-DnsServerCache -Force -ErrorAction Stop
                Write-Host "  DNS server cache cleared."
            }
            catch {
                Write-Host "  DNS Server role not installed or not accessible."
            }
        }
    }
    else {
        try {
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                Clear-DnsClientCache
            } -ErrorAction Stop
            Write-Host "  DNS client cache cleared."
        }
        catch {
            Write-Warning "  Failed to clear cache: $_"
        }
    }
}

Write-Host "`nDNS cache flush complete."
