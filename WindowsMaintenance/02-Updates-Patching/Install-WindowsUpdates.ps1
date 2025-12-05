#Requires -RunAsAdministrator
#Requires -Modules PSWindowsUpdate
<#
.SYNOPSIS
    Installs available Windows Updates.
.DESCRIPTION
    Uses PSWindowsUpdate module to check for and install updates.
    Install module first: Install-Module PSWindowsUpdate -Force
#>

[CmdletBinding()]
param(
    [switch]$AutoReboot,
    [string]$LogPath = "C:\Logs\WindowsUpdate.log"
)

# Ensure log directory exists
$LogDir = Split-Path $LogPath -Parent
if (-not (Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
}

Write-Host "Checking for Windows Updates..."
$Updates = Get-WindowsUpdate -AcceptAll

if ($Updates.Count -eq 0) {
    Write-Host "No updates available."
    exit
}

Write-Host "Found $($Updates.Count) updates. Installing..."

$InstallParams = @{
    AcceptAll = $true
    IgnoreReboot = -not $AutoReboot
}

Install-WindowsUpdate @InstallParams | Out-File -FilePath $LogPath -Append

Write-Host "Updates installed. Check log: $LogPath"
