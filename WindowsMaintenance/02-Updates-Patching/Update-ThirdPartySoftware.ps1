#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Updates third-party software using winget.
.DESCRIPTION
    Uses Windows Package Manager (winget) to update installed applications.
#>

[CmdletBinding()]
param(
    [switch]$All,
    [string[]]$Include
)

# Check if winget is available
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget is not installed. Please install App Installer from Microsoft Store."
    exit 1
}

Write-Host "Checking for available updates..."

if ($All) {
    winget upgrade --all --accept-package-agreements --accept-source-agreements
}
elseif ($Include) {
    foreach ($Package in $Include) {
        Write-Host "Updating: $Package"
        winget upgrade $Package --accept-package-agreements --accept-source-agreements
    }
}
else {
    # List available updates
    winget upgrade
}
