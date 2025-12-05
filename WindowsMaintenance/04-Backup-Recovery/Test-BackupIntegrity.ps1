<#
.SYNOPSIS
    Verifies backup file integrity.
.DESCRIPTION
    Tests backup archives for corruption and validates contents.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$BackupPath,

    [switch]$Detailed
)

if (-not (Test-Path $BackupPath)) {
    Write-Error "Backup path not found: $BackupPath"
    exit 1
}

$Archives = Get-ChildItem -Path $BackupPath -Filter "*.zip" -Recurse

if ($Archives.Count -eq 0) {
    Write-Warning "No ZIP archives found in: $BackupPath"
    exit
}

$Results = foreach ($Archive in $Archives) {
    Write-Host "Testing: $($Archive.Name)..." -NoNewline

    try {
        $TestResult = Test-Path $Archive.FullName -PathType Leaf

        # Try to read the archive
        $Zip = [System.IO.Compression.ZipFile]::OpenRead($Archive.FullName)
        $EntryCount = $Zip.Entries.Count
        $Zip.Dispose()

        Write-Host " OK ($EntryCount files)" -ForegroundColor Green

        [PSCustomObject]@{
            Archive = $Archive.Name
            Status = 'Valid'
            Files = $EntryCount
            SizeMB = [math]::Round($Archive.Length / 1MB, 2)
            LastModified = $Archive.LastWriteTime
        }
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red

        [PSCustomObject]@{
            Archive = $Archive.Name
            Status = 'Corrupted'
            Files = 0
            SizeMB = [math]::Round($Archive.Length / 1MB, 2)
            LastModified = $Archive.LastWriteTime
            Error = $_.Exception.Message
        }
    }
}

Write-Host "`nSummary:"
$Results | Format-Table -AutoSize

$CorruptCount = ($Results | Where-Object { $_.Status -eq 'Corrupted' }).Count
if ($CorruptCount -gt 0) {
    Write-Warning "$CorruptCount corrupted backup(s) found!"
}
