#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Rotates and archives old log files.
.DESCRIPTION
    Compresses logs older than specified days and removes archives older than retention period.
#>

[CmdletBinding()]
param(
    [string]$LogPath = "C:\Logs",
    [int]$CompressAfterDays = 7,
    [int]$DeleteAfterDays = 30
)

if (-not (Test-Path $LogPath)) {
    Write-Warning "Log path not found: $LogPath"
    exit
}

$ArchivePath = Join-Path $LogPath "Archive"
if (-not (Test-Path $ArchivePath)) {
    New-Item -Path $ArchivePath -ItemType Directory | Out-Null
}

# Compress old logs
$OldLogs = Get-ChildItem -Path $LogPath -Filter "*.log" |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$CompressAfterDays) }

foreach ($Log in $OldLogs) {
    $ArchiveName = Join-Path $ArchivePath "$($Log.BaseName)_$(Get-Date $Log.LastWriteTime -Format 'yyyyMMdd').zip"
    Compress-Archive -Path $Log.FullName -DestinationPath $ArchiveName -Force
    Remove-Item $Log.FullName -Force
    Write-Host "Archived: $($Log.Name)"
}

# Delete old archives
Get-ChildItem -Path $ArchivePath -Filter "*.zip" |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DeleteAfterDays) } |
    ForEach-Object {
        Remove-Item $_.FullName -Force
        Write-Host "Deleted old archive: $($_.Name)"
    }
