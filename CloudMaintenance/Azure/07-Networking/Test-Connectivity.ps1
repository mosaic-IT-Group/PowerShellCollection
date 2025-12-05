#Requires -Modules Az.Accounts, Az.Network
<#
.SYNOPSIS
    Tests network connectivity between Azure resources.
.DESCRIPTION
    Uses Network Watcher to test connectivity between VMs or to external endpoints.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SourceVMName,

    [Parameter(Mandatory)]
    [string]$SourceResourceGroup,

    [string]$DestinationVMName,
    [string]$DestinationResourceGroup,
    [string]$DestinationAddress,
    [int]$DestinationPort = 443,

    [ValidateSet('TCP', 'ICMP')]
    [string]$Protocol = 'TCP'
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

# Get source VM
$SourceVM = Get-AzVM -ResourceGroupName $SourceResourceGroup -Name $SourceVMName -ErrorAction Stop

Write-Host "Testing connectivity from: $SourceVMName" -ForegroundColor Cyan

# Get Network Watcher
$NW = Get-AzNetworkWatcher -Location $SourceVM.Location -ErrorAction SilentlyContinue

if (-not $NW) {
    Write-Error "Network Watcher not found in location: $($SourceVM.Location)"
    Write-Host "Enable Network Watcher first: Register-AzProviderFeature -FeatureName AllowNetworkWatcher -ProviderNamespace Microsoft.Network"
    exit 1
}

# Build destination
if ($DestinationVMName) {
    $DestVM = Get-AzVM -ResourceGroupName $DestinationResourceGroup -Name $DestinationVMName -ErrorAction Stop
    $DestinationAddress = $DestVM.Id
    Write-Host "Destination: $DestinationVMName (VM)"
} else {
    Write-Host "Destination: $DestinationAddress`:$DestinationPort"
}

Write-Host "Protocol: $Protocol"
Write-Host "`nRunning connectivity check..."

try {
    $Result = Test-AzNetworkWatcherConnectivity `
        -NetworkWatcher $NW `
        -SourceId $SourceVM.Id `
        -DestinationAddress $DestinationAddress `
        -DestinationPort $DestinationPort `
        -ProtocolConfiguration @{ Protocol = $Protocol } `
        -ErrorAction Stop

    Write-Host "`n=== Connectivity Result ===" -ForegroundColor Green

    $StatusColor = if ($Result.ConnectionStatus -eq 'Reachable') { 'Green' } else { 'Red' }
    Write-Host "Status: $($Result.ConnectionStatus)" -ForegroundColor $StatusColor
    Write-Host "Latency: $($Result.AvgLatencyInMs) ms"
    Write-Host "Min Latency: $($Result.MinLatencyInMs) ms"
    Write-Host "Max Latency: $($Result.MaxLatencyInMs) ms"
    Write-Host "Probes Sent: $($Result.ProbesSent)"
    Write-Host "Probes Failed: $($Result.ProbesFailed)"

    if ($Result.Hops) {
        Write-Host "`nHops:"
        foreach ($Hop in $Result.Hops) {
            Write-Host "  $($Hop.Type): $($Hop.Address) - $($Hop.NextHopIds -join ', ')"
        }
    }

    if ($Result.ConnectionStatus -ne 'Reachable') {
        Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
        Write-Host "  - Check NSG rules on source and destination"
        Write-Host "  - Verify route tables"
        Write-Host "  - Check if destination service is running on port $DestinationPort"
    }
}
catch {
    Write-Error "Connectivity test failed: $_"
}
