#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Rotates the local administrator password.
.DESCRIPTION
    Generates a new random password for the local Administrator account.
    Note: For enterprise environments, use Microsoft LAPS instead.
#>

[CmdletBinding()]
param(
    [int]$PasswordLength = 16,
    [string]$AdminAccount = "Administrator"
)

function New-RandomPassword {
    param([int]$Length = 16)

    $Chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*'
    $Password = -join (1..$Length | ForEach-Object { $Chars[(Get-Random -Maximum $Chars.Length)] })
    return $Password
}

$NewPassword = New-RandomPassword -Length $PasswordLength
$SecurePassword = ConvertTo-SecureString $NewPassword -AsPlainText -Force

try {
    $User = Get-LocalUser -Name $AdminAccount -ErrorAction Stop
    $User | Set-LocalUser -Password $SecurePassword

    Write-Host "Password for '$AdminAccount' has been reset."
    Write-Host "New password: $NewPassword"
    Write-Warning "Store this password securely and delete from console history!"
}
catch {
    Write-Error "Failed to reset password: $_"
}
