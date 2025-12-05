#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Creates a Windows System State backup.
.DESCRIPTION
    Uses wbadmin to create a system state backup to specified location.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$BackupTarget
)

# Verify Windows Server Backup feature
$Feature = Get-WindowsFeature -Name Windows-Server-Backup -ErrorAction SilentlyContinue
if (-not $Feature.Installed) {
    Write-Error "Windows Server Backup feature is not installed."
    Write-Host "Install with: Install-WindowsFeature Windows-Server-Backup"
    exit 1
}

if (-not (Test-Path $BackupTarget)) {
    Write-Error "Backup target path does not exist: $BackupTarget"
    exit 1
}

Write-Host "Starting System State backup to: $BackupTarget"
$Result = wbadmin start systemstatebackup -backupTarget:$BackupTarget -quiet

if ($LASTEXITCODE -eq 0) {
    Write-Host "System State backup completed successfully."
}
else {
    Write-Error "System State backup failed."
}
