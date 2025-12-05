<#
.SYNOPSIS
    Checks if a system reboot is pending.
.DESCRIPTION
    Checks various registry keys to determine if a reboot is required.
#>

[CmdletBinding()]
param()

$RebootRequired = $false
$Reasons = @()

# Windows Update
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
    $RebootRequired = $true
    $Reasons += "Windows Update"
}

# Component Based Servicing
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
    $RebootRequired = $true
    $Reasons += "Component Based Servicing"
}

# Pending File Rename Operations
$PendingFileRename = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue
if ($PendingFileRename) {
    $RebootRequired = $true
    $Reasons += "Pending File Rename"
}

# Computer Rename
$ComputerRename = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" -ErrorAction SilentlyContinue
$ActiveName = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName" -ErrorAction SilentlyContinue
if ($ComputerRename.ComputerName -ne $ActiveName.ComputerName) {
    $RebootRequired = $true
    $Reasons += "Computer Rename"
}

[PSCustomObject]@{
    ComputerName = $env:COMPUTERNAME
    RebootRequired = $RebootRequired
    Reasons = $Reasons -join ", "
}
