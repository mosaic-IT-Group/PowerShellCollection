<#
.SYNOPSIS
    Empties the Recycle Bin for all users.
.DESCRIPTION
    Clears all items from the Recycle Bin system-wide.
#>

[CmdletBinding()]
param(
    [switch]$Force
)

if ($Force -or $PSCmdlet.ShouldContinue("Empty Recycle Bin?", "Confirm")) {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "Recycle Bin emptied successfully."
}
