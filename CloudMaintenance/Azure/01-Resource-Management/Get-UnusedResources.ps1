#Requires -Modules Az.Accounts, Az.Resources, Az.Compute, Az.Network
<#
.SYNOPSIS
    Identifies unused Azure resources.
.DESCRIPTION
    Finds unattached disks, unused public IPs, empty resource groups, and orphaned NICs.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [switch]$ExportCsv,
    [string]$ExportPath = ".\UnusedResources.csv"
)

# Connect if needed
if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

$Results = @()

Write-Host "Scanning for unused resources..." -ForegroundColor Cyan

# Unattached Managed Disks
Write-Host "`nChecking for unattached disks..."
$UnattachedDisks = Get-AzDisk | Where-Object { $_.DiskState -eq 'Unattached' }
foreach ($Disk in $UnattachedDisks) {
    $Results += [PSCustomObject]@{
        ResourceType = 'Managed Disk'
        Name = $Disk.Name
        ResourceGroup = $Disk.ResourceGroupName
        Size = "$($Disk.DiskSizeGB) GB"
        Created = $Disk.TimeCreated
        MonthlyCost = "~$" + [math]::Round($Disk.DiskSizeGB * 0.05, 2)
    }
}

# Unused Public IPs
Write-Host "Checking for unused public IPs..."
$UnusedIPs = Get-AzPublicIpAddress | Where-Object { $null -eq $_.IpConfiguration }
foreach ($IP in $UnusedIPs) {
    $Results += [PSCustomObject]@{
        ResourceType = 'Public IP'
        Name = $IP.Name
        ResourceGroup = $IP.ResourceGroupName
        Size = $IP.Sku.Name
        Created = '-'
        MonthlyCost = "~$3.65"
    }
}

# Orphaned NICs
Write-Host "Checking for orphaned NICs..."
$OrphanedNICs = Get-AzNetworkInterface | Where-Object { $null -eq $_.VirtualMachine }
foreach ($NIC in $OrphanedNICs) {
    $Results += [PSCustomObject]@{
        ResourceType = 'Network Interface'
        Name = $NIC.Name
        ResourceGroup = $NIC.ResourceGroupName
        Size = '-'
        Created = '-'
        MonthlyCost = '$0'
    }
}

# Empty Resource Groups
Write-Host "Checking for empty resource groups..."
$ResourceGroups = Get-AzResourceGroup
foreach ($RG in $ResourceGroups) {
    $Resources = Get-AzResource -ResourceGroupName $RG.ResourceGroupName
    if ($Resources.Count -eq 0) {
        $Results += [PSCustomObject]@{
            ResourceType = 'Empty Resource Group'
            Name = $RG.ResourceGroupName
            ResourceGroup = '-'
            Size = '-'
            Created = '-'
            MonthlyCost = '$0'
        }
    }
}

# Output results
Write-Host "`n=== Unused Resources Report ===" -ForegroundColor Green
$Results | Format-Table -AutoSize

Write-Host "`nSummary:"
$Results | Group-Object ResourceType | Select-Object Name, Count | Format-Table -AutoSize

if ($ExportCsv) {
    $Results | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Exported to: $ExportPath"
}
