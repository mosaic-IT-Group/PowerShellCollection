#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Forces Group Policy update on local or remote computers.
.DESCRIPTION
    Runs gpupdate on specified computers to refresh Group Policy settings.
#>

[CmdletBinding()]
param(
    [string[]]$ComputerName = @($env:COMPUTERNAME),
    [switch]$Force
)

foreach ($Computer in $ComputerName) {
    Write-Host "Updating Group Policy on: $Computer"

    if ($Computer -eq $env:COMPUTERNAME) {
        if ($Force) {
            gpupdate /force /wait:0
        }
        else {
            gpupdate /wait:0
        }
    }
    else {
        $ScriptBlock = {
            param($Force)
            if ($Force) {
                gpupdate /force /wait:0
            }
            else {
                gpupdate /wait:0
            }
        }

        try {
            Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -ArgumentList $Force -ErrorAction Stop
            Write-Host "  Success" -ForegroundColor Green
        }
        catch {
            Write-Warning "  Failed: $_"
        }
    }
}
