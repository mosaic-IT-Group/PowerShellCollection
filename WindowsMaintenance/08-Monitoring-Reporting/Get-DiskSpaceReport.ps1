<#
.SYNOPSIS
    Generates disk space usage report.
.DESCRIPTION
    Reports on disk usage across local and remote computers with alerts for low space.
#>

[CmdletBinding()]
param(
    [string[]]$ComputerName = @($env:COMPUTERNAME),
    [int]$WarningThresholdPercent = 20,
    [int]$CriticalThresholdPercent = 10
)

$Results = foreach ($Computer in $ComputerName) {
    try {
        $Disks = Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $Computer -Filter "DriveType=3" -ErrorAction Stop

        foreach ($Disk in $Disks) {
            $FreePercent = [math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 2)

            $Status = if ($FreePercent -le $CriticalThresholdPercent) {
                'CRITICAL'
            }
            elseif ($FreePercent -le $WarningThresholdPercent) {
                'WARNING'
            }
            else {
                'OK'
            }

            [PSCustomObject]@{
                Computer = $Computer
                Drive = $Disk.DeviceID
                Label = $Disk.VolumeName
                'Size(GB)' = [math]::Round($Disk.Size / 1GB, 2)
                'Free(GB)' = [math]::Round($Disk.FreeSpace / 1GB, 2)
                'Free%' = $FreePercent
                Status = $Status
            }
        }
    }
    catch {
        [PSCustomObject]@{
            Computer = $Computer
            Drive = 'N/A'
            Label = 'ERROR'
            'Size(GB)' = 0
            'Free(GB)' = 0
            'Free%' = 0
            Status = "Error: $_"
        }
    }
}

Write-Host "Disk Space Report`n"
$Results | Format-Table -AutoSize

# Summary
$Critical = $Results | Where-Object { $_.Status -eq 'CRITICAL' }
$Warning = $Results | Where-Object { $_.Status -eq 'WARNING' }

if ($Critical) {
    Write-Host "`nCRITICAL - Low disk space:" -ForegroundColor Red
    $Critical | Select-Object Computer, Drive, 'Free(GB)', 'Free%' | Format-Table -AutoSize
}

if ($Warning) {
    Write-Host "`nWARNING - Disk space getting low:" -ForegroundColor Yellow
    $Warning | Select-Object Computer, Drive, 'Free(GB)', 'Free%' | Format-Table -AutoSize
}
