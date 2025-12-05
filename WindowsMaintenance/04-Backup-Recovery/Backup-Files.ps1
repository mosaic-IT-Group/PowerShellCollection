<#
.SYNOPSIS
    Backs up specified folders to a destination.
.DESCRIPTION
    Creates compressed backup of folders with timestamp.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string[]]$SourcePaths,

    [Parameter(Mandatory)]
    [string]$DestinationPath,

    [int]$RetentionDays = 30
)

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupName = "Backup_$Timestamp.zip"
$BackupFullPath = Join-Path $DestinationPath $BackupName

# Validate paths
foreach ($Path in $SourcePaths) {
    if (-not (Test-Path $Path)) {
        Write-Error "Source path not found: $Path"
        exit 1
    }
}

if (-not (Test-Path $DestinationPath)) {
    New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
}

Write-Host "Creating backup: $BackupFullPath"

try {
    Compress-Archive -Path $SourcePaths -DestinationPath $BackupFullPath -CompressionLevel Optimal
    $BackupSize = (Get-Item $BackupFullPath).Length / 1MB
    Write-Host "Backup created successfully. Size: $([math]::Round($BackupSize, 2)) MB"
}
catch {
    Write-Error "Backup failed: $_"
    exit 1
}

# Cleanup old backups
$OldBackups = Get-ChildItem -Path $DestinationPath -Filter "Backup_*.zip" |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) }

foreach ($OldBackup in $OldBackups) {
    Remove-Item $OldBackup.FullName -Force
    Write-Host "Removed old backup: $($OldBackup.Name)"
}
