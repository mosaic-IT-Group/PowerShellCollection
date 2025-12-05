#Requires -Modules DhcpServer
<#
.SYNOPSIS
    Monitors DHCP scope usage and availability.
.DESCRIPTION
    Reports on DHCP scope utilization and alerts on low availability.
#>

[CmdletBinding()]
param(
    [string]$DhcpServer = $env:COMPUTERNAME,
    [int]$WarningThreshold = 80
)

Write-Host "DHCP Scope Status for: $DhcpServer`n"

$Scopes = Get-DhcpServerv4Scope -ComputerName $DhcpServer -ErrorAction Stop

$Results = foreach ($Scope in $Scopes) {
    $Stats = Get-DhcpServerv4ScopeStatistics -ComputerName $DhcpServer -ScopeId $Scope.ScopeId

    $UsedPercent = [math]::Round($Stats.PercentageInUse, 2)

    [PSCustomObject]@{
        ScopeId = $Scope.ScopeId
        Name = $Scope.Name
        State = $Scope.State
        TotalAddresses = $Stats.AddressesFree + $Stats.AddressesInUse
        InUse = $Stats.AddressesInUse
        Free = $Stats.AddressesFree
        'Used%' = $UsedPercent
        Status = if ($UsedPercent -ge $WarningThreshold) { 'WARNING' } else { 'OK' }
    }
}

$Results | Format-Table -AutoSize

$HighUsage = $Results | Where-Object { $_.'Used%' -ge $WarningThreshold }
if ($HighUsage) {
    Write-Warning "The following scopes are above $WarningThreshold% utilization:"
    $HighUsage | Select-Object ScopeId, Name, 'Used%' | Format-Table -AutoSize
}
