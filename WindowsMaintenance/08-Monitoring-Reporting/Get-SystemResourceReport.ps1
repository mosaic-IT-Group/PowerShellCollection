<#
.SYNOPSIS
    Reports on CPU and memory usage.
.DESCRIPTION
    Provides current system resource utilization metrics.
#>

[CmdletBinding()]
param(
    [string[]]$ComputerName = @($env:COMPUTERNAME),
    [int]$TopProcesses = 5
)

foreach ($Computer in $ComputerName) {
    Write-Host "`n=== System Resources: $Computer ===" -ForegroundColor Cyan

    try {
        # CPU Usage
        $CPU = Get-CimInstance -ClassName Win32_Processor -ComputerName $Computer |
            Measure-Object -Property LoadPercentage -Average |
            Select-Object -ExpandProperty Average

        # Memory Usage
        $Memory = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Computer
        $TotalMemGB = [math]::Round($Memory.TotalVisibleMemorySize / 1MB, 2)
        $FreeMemGB = [math]::Round($Memory.FreePhysicalMemory / 1MB, 2)
        $UsedMemGB = $TotalMemGB - $FreeMemGB
        $MemPercent = [math]::Round(($UsedMemGB / $TotalMemGB) * 100, 2)

        # Uptime
        $Uptime = (Get-Date) - $Memory.LastBootUpTime

        Write-Host "`nCPU Usage: $CPU%"
        Write-Host "Memory: $UsedMemGB GB / $TotalMemGB GB ($MemPercent% used)"
        Write-Host "Uptime: $($Uptime.Days) days, $($Uptime.Hours) hours, $($Uptime.Minutes) minutes"

        # Top processes by CPU
        if ($Computer -eq $env:COMPUTERNAME) {
            Write-Host "`nTop $TopProcesses Processes by CPU:"
            Get-Process | Sort-Object CPU -Descending |
                Select-Object -First $TopProcesses Name, Id, CPU, @{N='MemMB';E={[math]::Round($_.WorkingSet64/1MB, 2)}} |
                Format-Table -AutoSize

            Write-Host "Top $TopProcesses Processes by Memory:"
            Get-Process | Sort-Object WorkingSet64 -Descending |
                Select-Object -First $TopProcesses Name, Id, @{N='MemMB';E={[math]::Round($_.WorkingSet64/1MB, 2)}} |
                Format-Table -AutoSize
        }
    }
    catch {
        Write-Warning "Failed to get data from $Computer`: $_"
    }
}
