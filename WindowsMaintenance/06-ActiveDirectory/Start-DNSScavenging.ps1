#Requires -RunAsAdministrator
#Requires -Modules DnsServer
<#
.SYNOPSIS
    Manages DNS scavenging settings and initiates scavenging.
.DESCRIPTION
    Configures and runs DNS scavenging to remove stale DNS records.
#>

[CmdletBinding()]
param(
    [string]$DnsServer = $env:COMPUTERNAME,

    [ValidateSet('Status', 'Enable', 'Scavenge')]
    [string]$Action = 'Status',

    [timespan]$NoRefreshInterval = (New-TimeSpan -Days 7),
    [timespan]$RefreshInterval = (New-TimeSpan -Days 7)
)

switch ($Action) {
    'Status' {
        Write-Host "DNS Scavenging Status for: $DnsServer`n"

        $ServerScavenging = Get-DnsServerScavenging -ComputerName $DnsServer
        Write-Host "Server Scavenging Settings:"
        $ServerScavenging | Format-List

        Write-Host "`nZone Aging Settings:"
        Get-DnsServerZone -ComputerName $DnsServer |
            Where-Object { $_.ZoneType -eq 'Primary' -and -not $_.IsAutoCreated } |
            ForEach-Object {
                $Aging = Get-DnsServerZoneAging -Name $_.ZoneName -ComputerName $DnsServer
                [PSCustomObject]@{
                    Zone = $_.ZoneName
                    AgingEnabled = $Aging.AgingEnabled
                    NoRefreshInterval = $Aging.NoRefreshInterval
                    RefreshInterval = $Aging.RefreshInterval
                }
            } | Format-Table -AutoSize
    }

    'Enable' {
        Write-Host "Enabling DNS Scavenging on: $DnsServer"

        Set-DnsServerScavenging -ComputerName $DnsServer `
            -ScavengingState $true `
            -ScavengingInterval (New-TimeSpan -Days 7) `
            -ApplyOnAllZones

        Write-Host "Scavenging enabled."
    }

    'Scavenge' {
        Write-Host "Starting DNS scavenging on: $DnsServer"
        Start-DnsServerScavenging -ComputerName $DnsServer -Force
        Write-Host "Scavenging initiated."
    }
}
