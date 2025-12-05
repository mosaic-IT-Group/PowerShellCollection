#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Removes old user profiles that haven't been used recently.
.DESCRIPTION
    Identifies and removes local user profiles older than specified days.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [int]$DaysInactive = 90,
    [string[]]$ExcludeUsers = @('Administrator', 'Default', 'Public')
)

$CutoffDate = (Get-Date).AddDays(-$DaysInactive)

$Profiles = Get-CimInstance -ClassName Win32_UserProfile |
    Where-Object {
        -not $_.Special -and
        $_.LocalPath -notmatch ($ExcludeUsers -join '|') -and
        $_.LastUseTime -lt $CutoffDate
    }

foreach ($Profile in $Profiles) {
    $Username = Split-Path $Profile.LocalPath -Leaf
    if ($PSCmdlet.ShouldProcess($Username, "Remove profile")) {
        Write-Host "Removing profile: $Username (Last used: $($Profile.LastUseTime))"
        $Profile | Remove-CimInstance
    }
}

Write-Host "`nProcessed $($Profiles.Count) old profiles."
