<#
.SYNOPSIS
    Clears browser cache for common browsers.
.DESCRIPTION
    Removes cached data from Chrome, Edge, and Firefox for all users.
#>

[CmdletBinding()]
param()

$UserProfiles = Get-ChildItem "C:\Users" -Directory | Where-Object { $_.Name -notin @('Public', 'Default') }

foreach ($User in $UserProfiles) {
    $CachePaths = @(
        # Chrome
        "$($User.FullName)\AppData\Local\Google\Chrome\User Data\Default\Cache",
        # Edge
        "$($User.FullName)\AppData\Local\Microsoft\Edge\User Data\Default\Cache",
        # Firefox
        "$($User.FullName)\AppData\Local\Mozilla\Firefox\Profiles\*\cache2"
    )

    foreach ($Path in $CachePaths) {
        if (Test-Path $Path) {
            $Size = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum

            Remove-Item "$Path\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Cleared: $Path ($([math]::Round($Size/1MB, 2)) MB)"
        }
    }
}
