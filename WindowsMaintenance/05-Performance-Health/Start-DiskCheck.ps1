#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Schedules or runs CHKDSK on a volume.
.DESCRIPTION
    Checks disk for errors. For system drives, schedules check on next reboot.
#>

[CmdletBinding()]
param(
    [string]$DriveLetter = 'C',
    [switch]$ScheduleReboot
)

$Volume = "${DriveLetter}:"

Write-Host "Checking disk health for $Volume..."

# First, run a read-only scan
$ScanResult = Repair-Volume -DriveLetter $DriveLetter -Scan

Write-Host "Scan result: $ScanResult"

if ($ScanResult -eq 'NoErrorsFound') {
    Write-Host "No errors found on $Volume"
}
else {
    Write-Warning "Errors detected on $Volume"

    if ($DriveLetter -eq 'C') {
        Write-Host "System drive requires offline repair. Scheduling for next reboot..."
        # Schedule CHKDSK on next boot
        $null = cmd /c "echo Y | chkdsk $Volume /F /R /X" 2>&1

        if ($ScheduleReboot) {
            Write-Host "Rebooting in 60 seconds..."
            shutdown /r /t 60 /c "Scheduled disk check requires reboot"
        }
        else {
            Write-Host "Please reboot to complete disk check."
        }
    }
    else {
        Write-Host "Attempting online repair..."
        Repair-Volume -DriveLetter $DriveLetter -OfflineScanAndFix
    }
}
