#Requires -Modules Az.Accounts, Az.Security
<#
.SYNOPSIS
    Retrieves Azure Security Center recommendations.
.DESCRIPTION
    Lists security recommendations and their severity.
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [ValidateSet('All', 'High', 'Medium', 'Low')]
    [string]$Severity = 'All',
    [switch]$ExportCsv,
    [string]$ExportPath = ".\SecurityRecommendations.csv"
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

Write-Host "Retrieving security recommendations..." -ForegroundColor Cyan

$Recommendations = Get-AzSecurityTask -ErrorAction SilentlyContinue

if (-not $Recommendations) {
    Write-Host "No security recommendations found or Security Center not enabled."
    exit
}

$Results = foreach ($Rec in $Recommendations) {
    [PSCustomObject]@{
        Name = $Rec.Name
        RecommendationType = $Rec.RecommendationType
        Severity = $Rec.SecurityTaskParameters.severity
        State = $Rec.State
        ResourceId = $Rec.SecurityTaskParameters.resourceId
    }
}

if ($Severity -ne 'All') {
    $Results = $Results | Where-Object { $_.Severity -eq $Severity }
}

Write-Host "`n=== Security Recommendations ===" -ForegroundColor Green

# Summary by severity
$Results | Group-Object Severity | ForEach-Object {
    $Color = switch ($_.Name) {
        'High' { 'Red' }
        'Medium' { 'Yellow' }
        'Low' { 'Gray' }
        default { 'White' }
    }
    Write-Host "$($_.Name): $($_.Count)" -ForegroundColor $Color
}

Write-Host ""
$Results | Format-Table Name, Severity, State -AutoSize

if ($ExportCsv) {
    $Results | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Exported to: $ExportPath"
}
