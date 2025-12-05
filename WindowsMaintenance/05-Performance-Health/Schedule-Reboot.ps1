#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Schedules a system reboot at a specified time.
.DESCRIPTION
    Creates a scheduled task to reboot the system at the specified time.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [datetime]$RebootTime,

    [string]$Reason = "Scheduled maintenance reboot",

    [switch]$Cancel
)

$TaskName = "ScheduledMaintenanceReboot"

if ($Cancel) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "Scheduled reboot cancelled."
    exit
}

# Remove existing task if present
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

$Action = New-ScheduledTaskAction -Execute "shutdown.exe" -Argument "/r /t 60 /c `"$Reason`""
$Trigger = New-ScheduledTaskTrigger -Once -At $RebootTime
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings

Register-ScheduledTask -TaskName $TaskName -InputObject $Task | Out-Null

Write-Host "Reboot scheduled for: $RebootTime"
Write-Host "Reason: $Reason"
Write-Host "`nTo cancel, run: .\Schedule-Reboot.ps1 -Cancel"
