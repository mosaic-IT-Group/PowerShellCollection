#Requires -Modules Az.Accounts, Az.Network
<#
.SYNOPSIS
    Lists all public IP addresses and their associations.
.DESCRIPTION
    Reports on public IPs, their assignments, and identifies unused IPs.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [switch]$UnassignedOnly
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Retrieving public IP addresses..." -ForegroundColor Cyan

$PublicIPs = Get-AzPublicIpAddress

$Results = foreach ($PIP in $PublicIPs) {
    $AssociatedTo = if ($PIP.IpConfiguration) {
        $ConfigId = $PIP.IpConfiguration.Id
        if ($ConfigId -match '/networkInterfaces/') {
            "NIC: $($ConfigId.Split('/')[-3])"
        } elseif ($ConfigId -match '/frontendIPConfigurations/') {
            "LB: $($ConfigId.Split('/')[-3])"
        } elseif ($ConfigId -match '/bastionHostIpConfigurations/') {
            "Bastion"
        } else {
            "Other"
        }
    } else {
        'Unassigned'
    }

    $MonthlyCost = switch ($PIP.Sku.Name) {
        'Standard' { '~$3.65' }
        'Basic' { '~$2.92' }
        default { 'Unknown' }
    }

    [PSCustomObject]@{
        Name = $PIP.Name
        ResourceGroup = $PIP.ResourceGroupName
        Location = $PIP.Location
        IPAddress = $PIP.IpAddress
        AllocationMethod = $PIP.PublicIpAllocationMethod
        SKU = $PIP.Sku.Name
        AssociatedTo = $AssociatedTo
        MonthlyCost = $MonthlyCost
    }
}

if ($UnassignedOnly) {
    $Results = $Results | Where-Object { $_.AssociatedTo -eq 'Unassigned' }
}

Write-Host "`n=== Public IP Addresses ===" -ForegroundColor Green
Write-Host "Total: $($Results.Count)"
Write-Host "Assigned: $(($Results | Where-Object { $_.AssociatedTo -ne 'Unassigned' }).Count)"
Write-Host "Unassigned: $(($Results | Where-Object { $_.AssociatedTo -eq 'Unassigned' }).Count)"

Write-Host ""
$Results | Format-Table Name, IPAddress, SKU, AllocationMethod, AssociatedTo, MonthlyCost -AutoSize

$Unassigned = $Results | Where-Object { $_.AssociatedTo -eq 'Unassigned' }
if ($Unassigned) {
    $TotalWaste = $Unassigned.Count * 3.65
    Write-Host "`nUnassigned IPs (potential monthly savings: ~`$$TotalWaste):" -ForegroundColor Yellow
    $Unassigned | Select-Object Name, ResourceGroup, IPAddress | Format-Table -AutoSize
}
