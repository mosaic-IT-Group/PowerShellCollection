#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Clears temporary files from common Windows locations.
.DESCRIPTION
    Removes temporary files from Windows Temp, User Temp, and Windows Update cache.
#>

[CmdletBinding()]
param(
    [int]$DaysOld = 7
)

$ErrorActionPreference = 'SilentlyContinue'

$TempFolders = @(
    "$env:TEMP",
    "$env:SystemRoot\Temp",
    "$env:SystemRoot\SoftwareDistribution\Download"
)

$TotalFreed = 0

foreach ($Folder in $TempFolders) {
    if (Test-Path $Folder) {
        $Files = Get-ChildItem -Path $Folder -Recurse -File |
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysOld) }

        $Size = ($Files | Measure-Object -Property Length -Sum).Sum
        $Files | Remove-Item -Force -ErrorAction SilentlyContinue

        $TotalFreed += $Size
        Write-Host "Cleaned: $Folder - Freed: $([math]::Round($Size/1MB, 2)) MB"
    }
}

Write-Host "`nTotal space freed: $([math]::Round($TotalFreed/1MB, 2)) MB"
