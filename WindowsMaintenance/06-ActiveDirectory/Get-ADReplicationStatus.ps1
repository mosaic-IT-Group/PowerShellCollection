#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Monitors AD replication health across domain controllers.
.DESCRIPTION
    Checks replication status and identifies any failures.
#>

[CmdletBinding()]
param()

Write-Host "Checking AD Replication Status...`n"

# Get all domain controllers
$DCs = Get-ADDomainController -Filter *

Write-Host "Domain Controllers:"
$DCs | Select-Object Name, IPv4Address, Site, IsGlobalCatalog | Format-Table -AutoSize

# Check replication status
$ReplStatus = Get-ADReplicationPartnerMetadata -Target $env:USERDNSDOMAIN -Scope Domain -ErrorAction SilentlyContinue

if ($ReplStatus) {
    Write-Host "`nReplication Partner Status:"
    $ReplStatus | Select-Object Server, Partner, LastReplicationSuccess, LastReplicationResult |
        Format-Table -AutoSize

    $Failures = $ReplStatus | Where-Object { $_.LastReplicationResult -ne 0 }
    if ($Failures) {
        Write-Warning "Replication failures detected!"
        $Failures | Format-List Server, Partner, LastReplicationResult, LastReplicationAttempt
    }
}

# Run repadmin for detailed status
Write-Host "`nDetailed Replication Summary:"
repadmin /replsummary

# Check for replication queue
Write-Host "`nReplication Queue:"
repadmin /queue
