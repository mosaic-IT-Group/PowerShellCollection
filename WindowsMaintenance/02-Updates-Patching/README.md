# Updates & Patching

Scripts for managing Windows and software updates.

## Scripts

### Install-WindowsUpdates.ps1

Automates Windows Update installation using the PSWindowsUpdate module.

**Requirements:**
- PSWindowsUpdate module (`Install-Module PSWindowsUpdate -Force`)

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-AutoReboot` | switch | false | Automatically reboot if required |
| `-LogPath` | string | C:\Logs\WindowsUpdate.log | Path for update log |

**Example:**
```powershell
# Install updates without auto-reboot
.\Install-WindowsUpdates.ps1

# Install updates and reboot if needed
.\Install-WindowsUpdates.ps1 -AutoReboot
```

---

### Update-ThirdPartySoftware.ps1

Updates third-party applications using Windows Package Manager (winget).

**Requirements:**
- winget (App Installer from Microsoft Store)

**Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-All` | switch | false | Update all available packages |
| `-Include` | string[] | - | Specific packages to update |

**Example:**
```powershell
# List available updates
.\Update-ThirdPartySoftware.ps1

# Update all packages
.\Update-ThirdPartySoftware.ps1 -All

# Update specific packages
.\Update-ThirdPartySoftware.ps1 -Include "7zip.7zip", "Notepad++.Notepad++"
```

---

### Update-Drivers.ps1

Searches for and installs driver updates via Windows Update catalog.

**Example:**
```powershell
.\Update-Drivers.ps1
```

**Behavior:**
1. Connects to Windows Update
2. Searches for driver-type updates
3. Lists available driver updates
4. Installs all found updates

---

### Get-PendingReboot.ps1

Checks if the system requires a reboot from various sources.

**Checks:**
- Windows Update pending reboot
- Component Based Servicing (CBS)
- Pending file rename operations
- Computer rename pending

**Example:**
```powershell
.\Get-PendingReboot.ps1
```

**Output:**
```
ComputerName    RebootRequired Reasons
------------    -------------- -------
WORKSTATION01   True           Windows Update, Pending File Rename
```

**Use Case:** Run before maintenance windows to identify systems needing reboots.
