<#
.SYNOPSIS
    Tests network connectivity to critical endpoints.
.DESCRIPTION
    Performs ping and port connectivity tests to specified targets.
#>

[CmdletBinding()]
param(
    [hashtable]$Targets = @{
        'Google DNS' = @{ Host = '8.8.8.8'; Port = 53 }
        'Microsoft' = @{ Host = 'www.microsoft.com'; Port = 443 }
        'Domain Controller' = @{ Host = $env:LOGONSERVER.TrimStart('\\'); Port = 389 }
    },
    [int]$TimeoutSeconds = 5
)

Write-Host "Network Connectivity Test`n"

$Results = foreach ($Name in $Targets.Keys) {
    $Target = $Targets[$Name]
    $Host_ = $Target.Host
    $Port = $Target.Port

    Write-Host "Testing: $Name ($Host_`:$Port)..." -NoNewline

    # Ping test
    $Ping = Test-Connection -ComputerName $Host_ -Count 1 -Quiet -ErrorAction SilentlyContinue

    # Port test
    $TcpTest = Test-NetConnection -ComputerName $Host_ -Port $Port -WarningAction SilentlyContinue

    $Status = if ($TcpTest.TcpTestSucceeded) {
        Write-Host " OK" -ForegroundColor Green
        'Connected'
    }
    elseif ($Ping) {
        Write-Host " Ping OK, Port Closed" -ForegroundColor Yellow
        'Ping Only'
    }
    else {
        Write-Host " FAILED" -ForegroundColor Red
        'Unreachable'
    }

    [PSCustomObject]@{
        Name = $Name
        Host = $Host_
        Port = $Port
        Ping = $Ping
        PortOpen = $TcpTest.TcpTestSucceeded
        Latency = if ($TcpTest.PingReplyDetails) { "$($TcpTest.PingReplyDetails.RoundtripTime)ms" } else { 'N/A' }
        Status = $Status
    }
}

Write-Host "`nSummary:"
$Results | Format-Table -AutoSize

$Failed = $Results | Where-Object { $_.Status -eq 'Unreachable' }
if ($Failed) {
    Write-Warning "$($Failed.Count) target(s) unreachable!"
}
