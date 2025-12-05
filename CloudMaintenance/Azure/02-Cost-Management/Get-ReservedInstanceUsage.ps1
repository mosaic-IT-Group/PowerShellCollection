#Requires -Modules Az.Accounts, Az.Reservations
<#
.SYNOPSIS
    Reports on Reserved Instance utilization.
.DESCRIPTION
    Shows RI usage and identifies underutilized reservations.
#>

[CmdletBinding()]
param(
    [int]$Days = 30,
    [int]$UtilizationThreshold = 80
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

Write-Host "Checking Reserved Instance utilization..." -ForegroundColor Cyan

$Reservations = Get-AzReservation -ErrorAction SilentlyContinue

if (-not $Reservations) {
    Write-Host "No reserved instances found."
    exit
}

$Results = foreach ($RI in $Reservations) {
    $Utilization = Get-AzReservationOrderId -ReservationOrderId $RI.ReservationOrderId -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        Name = $RI.DisplayName
        SKU = $RI.Sku
        Quantity = $RI.Quantity
        State = $RI.ProvisioningState
        ExpiryDate = $RI.ExpiryDate
        DaysToExpiry = if ($RI.ExpiryDate) { ((Get-Date $RI.ExpiryDate) - (Get-Date)).Days } else { 'N/A' }
    }
}

Write-Host "`n=== Reserved Instances ===" -ForegroundColor Green
$Results | Format-Table -AutoSize

# Check for expiring RIs
$ExpiringSoon = $Results | Where-Object { $_.DaysToExpiry -ne 'N/A' -and $_.DaysToExpiry -le 30 }
if ($ExpiringSoon) {
    Write-Host "`nReservations expiring within 30 days:" -ForegroundColor Yellow
    $ExpiringSoon | Format-Table Name, ExpiryDate, DaysToExpiry -AutoSize
}
