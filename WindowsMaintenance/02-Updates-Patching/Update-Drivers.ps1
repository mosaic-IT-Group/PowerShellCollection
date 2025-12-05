#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Checks for and installs driver updates via Windows Update.
.DESCRIPTION
    Searches for driver updates through Windows Update catalog.
#>

[CmdletBinding()]
param()

Write-Host "Searching for driver updates..."

$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

# Search for driver updates
$SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Driver'")

if ($SearchResult.Updates.Count -eq 0) {
    Write-Host "No driver updates available."
    exit
}

Write-Host "Found $($SearchResult.Updates.Count) driver updates:"

$UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl

foreach ($Update in $SearchResult.Updates) {
    Write-Host "  - $($Update.Title)"
    $UpdatesToInstall.Add($Update) | Out-Null
}

$Installer = $UpdateSession.CreateUpdateInstaller()
$Installer.Updates = $UpdatesToInstall

Write-Host "`nInstalling driver updates..."
$InstallResult = $Installer.Install()

Write-Host "Installation complete. Result: $($InstallResult.ResultCode)"
