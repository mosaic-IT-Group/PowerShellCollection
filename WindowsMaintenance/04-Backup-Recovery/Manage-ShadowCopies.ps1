#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Manages Volume Shadow Copies (VSS).
.DESCRIPTION
    Lists, creates, or removes shadow copies for specified volumes.
#>

[CmdletBinding()]
param(
    [ValidateSet('List', 'Create', 'Cleanup')]
    [string]$Action = 'List',

    [string]$Volume = 'C:',

    [int]$KeepCount = 5
)

switch ($Action) {
    'List' {
        $Shadows = Get-WmiObject Win32_ShadowCopy |
            Select-Object ID, InstallDate, VolumeName, @{N='SizeGB';E={[math]::Round($_.Count/1GB, 2)}}

        if ($Shadows) {
            Write-Host "Existing Shadow Copies:"
            $Shadows | Format-Table -AutoSize
        }
        else {
            Write-Host "No shadow copies found."
        }
    }

    'Create' {
        Write-Host "Creating shadow copy for $Volume..."
        $WMI = [WMICLASS]"root\cimv2:Win32_ShadowCopy"
        $Result = $WMI.Create($Volume, "ClientAccessible")

        if ($Result.ReturnValue -eq 0) {
            Write-Host "Shadow copy created successfully."
        }
        else {
            Write-Error "Failed to create shadow copy. Return code: $($Result.ReturnValue)"
        }
    }

    'Cleanup' {
        $Shadows = Get-WmiObject Win32_ShadowCopy |
            Where-Object { $_.VolumeName -like "*$($Volume.TrimEnd(':'))*" } |
            Sort-Object InstallDate -Descending

        if ($Shadows.Count -gt $KeepCount) {
            $ToDelete = $Shadows | Select-Object -Skip $KeepCount
            foreach ($Shadow in $ToDelete) {
                Write-Host "Removing shadow copy from: $($Shadow.InstallDate)"
                $Shadow.Delete()
            }
            Write-Host "Cleanup complete. Kept $KeepCount most recent copies."
        }
        else {
            Write-Host "No cleanup needed. Current count: $($Shadows.Count)"
        }
    }
}
