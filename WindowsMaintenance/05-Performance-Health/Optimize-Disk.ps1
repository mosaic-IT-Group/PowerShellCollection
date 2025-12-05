#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Optimizes disk drives (defrag for HDD, TRIM for SSD).
.DESCRIPTION
    Detects drive type and runs appropriate optimization.
#>

[CmdletBinding()]
param(
    [string]$DriveLetter = 'C'
)

$Drive = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq 0 }
$Volume = Get-Volume -DriveLetter $DriveLetter

Write-Host "Analyzing drive $DriveLetter`:"
Write-Host "  Media Type: $($Drive.MediaType)"
Write-Host "  Size: $([math]::Round($Volume.Size/1GB, 2)) GB"
Write-Host "  Free Space: $([math]::Round($Volume.SizeRemaining/1GB, 2)) GB"

if ($Drive.MediaType -eq 'SSD') {
    Write-Host "`nRunning TRIM optimization for SSD..."
    Optimize-Volume -DriveLetter $DriveLetter -ReTrim -Verbose
}
else {
    Write-Host "`nRunning defragmentation for HDD..."
    Optimize-Volume -DriveLetter $DriveLetter -Defrag -Verbose
}

Write-Host "`nOptimization complete."
