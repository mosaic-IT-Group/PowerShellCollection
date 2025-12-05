#Requires -Modules Az.Accounts, Az.Compute
<#
.SYNOPSIS
    Stops VMs based on schedule tags or inactivity.
.DESCRIPTION
    Deallocates VMs tagged for auto-shutdown or running outside business hours.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$SubscriptionId,
    [string]$TagName = 'AutoShutdown',
    [string]$TagValue = 'true',
    [switch]$BusinessHoursOnly,
    [int]$BusinessStart = 8,
    [int]$BusinessEnd = 18
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

$CurrentHour = (Get-Date).Hour
$IsBusinessHours = $CurrentHour -ge $BusinessStart -and $CurrentHour -lt $BusinessEnd

Write-Host "Current time: $(Get-Date -Format 'HH:mm')" -ForegroundColor Cyan
Write-Host "Business hours: $($BusinessStart):00 - $($BusinessEnd):00"
Write-Host "Is business hours: $IsBusinessHours"

# Get running VMs
$RunningVMs = Get-AzVM -Status | Where-Object { $_.PowerState -eq 'VM running' }

$VMsToStop = @()

foreach ($VM in $RunningVMs) {
    $ShouldStop = $false

    # Check for AutoShutdown tag
    $VMDetails = Get-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name
    if ($VMDetails.Tags[$TagName] -eq $TagValue) {
        $ShouldStop = $true
        $Reason = "Tagged for auto-shutdown"
    }

    # Check business hours
    if ($BusinessHoursOnly -and -not $IsBusinessHours) {
        $DevTag = $VMDetails.Tags['Environment']
        if ($DevTag -in @('Dev', 'Development', 'Test', 'Staging')) {
            $ShouldStop = $true
            $Reason = "Non-production VM outside business hours"
        }
    }

    if ($ShouldStop) {
        $VMsToStop += [PSCustomObject]@{
            Name = $VM.Name
            ResourceGroup = $VM.ResourceGroupName
            Size = $VMDetails.HardwareProfile.VmSize
            Reason = $Reason
        }
    }
}

if ($VMsToStop.Count -eq 0) {
    Write-Host "`nNo VMs to stop."
    exit
}

Write-Host "`nVMs to stop:"
$VMsToStop | Format-Table -AutoSize

foreach ($VM in $VMsToStop) {
    if ($PSCmdlet.ShouldProcess($VM.Name, "Stop and deallocate VM")) {
        Write-Host "Stopping: $($VM.Name)..." -NoNewline
        Stop-AzVM -ResourceGroupName $VM.ResourceGroup -Name $VM.Name -Force -NoWait | Out-Null
        Write-Host " Initiated" -ForegroundColor Green
    }
}

Write-Host "`nShutdown initiated for $($VMsToStop.Count) VMs."
