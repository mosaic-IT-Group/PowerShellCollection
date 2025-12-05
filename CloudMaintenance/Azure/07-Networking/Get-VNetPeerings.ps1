#Requires -Modules Az.Accounts, Az.Network
<#
.SYNOPSIS
    Lists VNet peering connections and their status.
.DESCRIPTION
    Reports on virtual network peerings across the subscription.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [switch]$DisconnectedOnly
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Retrieving VNet peerings..." -ForegroundColor Cyan

$VNets = Get-AzVirtualNetwork

$Results = @()

foreach ($VNet in $VNets) {
    foreach ($Peering in $VNet.VirtualNetworkPeerings) {
        $RemoteVNet = $Peering.RemoteVirtualNetwork.Id.Split('/')[-1]

        $Status = if ($Peering.PeeringState -eq 'Connected') {
            'Connected'
        } else {
            'Disconnected'
        }

        $Results += [PSCustomObject]@{
            LocalVNet = $VNet.Name
            LocalResourceGroup = $VNet.ResourceGroupName
            RemoteVNet = $RemoteVNet
            PeeringName = $Peering.Name
            Status = $Status
            AllowVNetAccess = $Peering.AllowVirtualNetworkAccess
            AllowForwardedTraffic = $Peering.AllowForwardedTraffic
            AllowGatewayTransit = $Peering.AllowGatewayTransit
            UseRemoteGateways = $Peering.UseRemoteGateways
        }
    }
}

if ($DisconnectedOnly) {
    $Results = $Results | Where-Object { $_.Status -eq 'Disconnected' }
}

if (-not $Results) {
    Write-Host "No VNet peerings found."
    exit
}

Write-Host "`n=== VNet Peerings ===" -ForegroundColor Green
Write-Host "Total: $($Results.Count)"
Write-Host "Connected: $(($Results | Where-Object { $_.Status -eq 'Connected' }).Count)" -ForegroundColor Green
Write-Host "Disconnected: $(($Results | Where-Object { $_.Status -eq 'Disconnected' }).Count)" -ForegroundColor $(if (($Results | Where-Object { $_.Status -eq 'Disconnected' }).Count -gt 0) { 'Red' } else { 'Green' })

Write-Host ""
$Results | Format-Table LocalVNet, RemoteVNet, Status, AllowVNetAccess, AllowForwardedTraffic -AutoSize

$Disconnected = $Results | Where-Object { $_.Status -eq 'Disconnected' }
if ($Disconnected) {
    Write-Host "`nDisconnected peerings require attention:" -ForegroundColor Yellow
    $Disconnected | Select-Object LocalVNet, RemoteVNet, PeeringName | Format-Table -AutoSize
}
