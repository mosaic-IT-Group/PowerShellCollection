#Requires -Modules Az.Accounts, Az.Resources
<#
.SYNOPSIS
    Audits resource tagging compliance.
.DESCRIPTION
    Identifies resources missing required tags.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string[]]$RequiredTags = @('Environment', 'Owner', 'CostCenter'),
    [string]$ResourceGroupName,
    [switch]$ExportCsv,
    [string]$ExportPath = ".\TaggingReport.csv"
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Auditing tags: $($RequiredTags -join ', ')" -ForegroundColor Cyan

$Params = @{}
if ($ResourceGroupName) {
    $Params.ResourceGroupName = $ResourceGroupName
}

$Resources = Get-AzResource @Params

$Results = foreach ($Resource in $Resources) {
    $MissingTags = @()
    foreach ($Tag in $RequiredTags) {
        if (-not $Resource.Tags -or -not $Resource.Tags.ContainsKey($Tag)) {
            $MissingTags += $Tag
        }
    }

    [PSCustomObject]@{
        Name = $Resource.Name
        ResourceGroup = $Resource.ResourceGroupName
        Type = $Resource.ResourceType.Split('/')[-1]
        MissingTags = $MissingTags -join ', '
        Compliant = $MissingTags.Count -eq 0
        CurrentTags = if ($Resource.Tags) { ($Resource.Tags.Keys -join ', ') } else { 'None' }
    }
}

# Summary
$Compliant = ($Results | Where-Object { $_.Compliant }).Count
$NonCompliant = ($Results | Where-Object { -not $_.Compliant }).Count

Write-Host "`n=== Tagging Compliance Report ===" -ForegroundColor Green
Write-Host "Total Resources: $($Results.Count)"
Write-Host "Compliant: $Compliant" -ForegroundColor Green
Write-Host "Non-Compliant: $NonCompliant" -ForegroundColor $(if ($NonCompliant -gt 0) { 'Yellow' } else { 'Green' })

Write-Host "`nNon-Compliant Resources:"
$Results | Where-Object { -not $_.Compliant } | Format-Table Name, ResourceGroup, Type, MissingTags -AutoSize

if ($ExportCsv) {
    $Results | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Exported to: $ExportPath"
}
