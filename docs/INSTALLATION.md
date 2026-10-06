# Installation

`PasswordGen.PS` can be installed from the PowerShell Gallery or installed manually using the offline installation package.

The module supports:

- Windows PowerShell 5.1
- PowerShell 7+ on Windows/Linux

---

## PowerShell Gallery Installation

### Current User

```powershell
Install-Module `
    -Name PasswordGen.PS `
    -Scope CurrentUser
```

### All Users

```powershell
Install-Module `
    -Name PasswordGen.PS `
    -Scope AllUsers
```

### Verify Installation

```powershell
Get-Module `
    -Name PasswordGen.PS `
    -ListAvailable
```

Example:

```text
ModuleType Version Name           ExportedCommands
---------- ------- ----           ----------------
Script     1.1.0   PasswordGen.PS {New-PGenRandomPassword, New-PGenRandomPassphrase}
```

---

## Offline Installation Method

Offline installation is intended for:

- Air-gapped environments
- Restricted corporate environments
- Computers without internet access
- Systems where PowerShell Gallery access is blocked

---

### Download the Release Package

Download the release ZIP package and extract it locally.

Example:

```text
PasswordGen.PS
│
├── PasswordGen.PS.psd1
├── PasswordGen.PS.psm1
├── installOffline.ps1
├── uninstallOffline.ps1
│
└── source
```

---

### Install Using Default Scope

Run:

```powershell
.\installOffline.ps1
```

The installer automatically selects the installation scope:

| User Type            | Scope       |
| -------------------- | ----------- |
| Standard User        | CurrentUser |
| Administrator / Root | AllUsers    |

Example:

```text
Success. Installed to
C:\Users\June\Documents\PowerShell\Modules\PasswordGen.PS\1.1.0
```

---

### Install for Current User

The module is installed only for the current user.

```powershell
.\installOffline.ps1 `
    -Scope CurrentUser
```

### Windows PowerShell

Installed to:

```text
%USERPROFILE%\Documents\WindowsPowerShell\Modules
```

### PowerShell 7+

Installed to:

```text
%USERPROFILE%\Documents\PowerShell\Modules
```

### Linux (CurrentUser)

Installed to:

```text
~/.local/share/powershell/Modules
```

---

## Install for All Users

The module is installed for all users on the computer.

### Windows

```powershell
.\installOffline.ps1 `
    -Scope AllUsers
```

Administrative privileges are required.

Installed to:

```text
C:\Program Files\WindowsPowerShell\Modules
```

or

```text
C:\Program Files\PowerShell\Modules
```

depending on the PowerShell edition.

### Linux (AllUsers)

```powershell
sudo pwsh ./installOffline.ps1 `
    -Scope AllUsers
```

Installed to:

```text
/usr/local/share/powershell/Modules
```

---

## Verify Offline Installation

Verify that the module is available:

```powershell
Get-Module `
    -Name PasswordGen.PS `
    -ListAvailable
```

Import the module:

```powershell
Import-Module PasswordGen.PS
```

List exported commands:

```powershell
Get-Command `
    -Module PasswordGen.PS
```

Example:

```text
CommandType Name
----------- ----
Function    New-PGenRandomPassword
Function    New-PGenRandomPassphrase
```

---

## Verify Word List Loading

The passphrase generator relies on the bundled EFF Large Word List.

Verify functionality:

```powershell
New-PGenRandomPassphrase
```

Example:

```text
grudge-smuggler-symphonic-squeegee
```

If this command succeeds, the bundled word list was loaded successfully during module import.

---

## Updating the Module

### PowerShell Gallery

```powershell
Update-Module PasswordGen.PS
```

### Offline Installation

Download the newer release and install it using:

```powershell
.\installOffline.ps1
```

Multiple versions can coexist side-by-side.

Example:

```text
PasswordGen.PS
├── 1.0.0
├── 1.0.1
└── 1.1.0
```

PowerShell automatically loads the newest version by default.

---

## Uninstalling the Module

### Remove a Loaded Module

```powershell
Remove-Module PasswordGen.PS
```

This unloads the module from the current session only.

It does not uninstall the module.

---

### Offline Uninstallation

Run:

```powershell
.\uninstallOffline.ps1
```

The uninstall script:

- Removes all installed versions of PasswordGen.PS
- Removes the module from the current PowerShell session
- Removes installed module files
- Cleans up empty module folders

Example:

```text
Removed PasswordGen.PS version 1.1.0
```

---

## Troubleshooting

### Module Not Found

Verify the module is installed:

```powershell
Get-Module `
    -Name PasswordGen.PS `
    -ListAvailable
```

Verify the installation path exists:

```powershell
$env:PSModulePath -split ';'
```

On Non-Windows:

```powershell
$env:PSModulePath -split ':'
```

---

### Import Fails

Import the module with verbose output:

```powershell
Import-Module PasswordGen.PS `
    -Verbose
```

Review any error messages displayed during import.

---

### Passphrase Generator Reports Missing Word List

Example error:

```text
The module word list was not loaded or has (0) usable words.
```

Verify that the EFF Large Word List exists within the installed module folder.

Example:

```text
PasswordGen.PS
└── source
    └── data
        └── eff_large_wordlist.txt
```

If the file is missing, reinstall the module.

---

## Installation Scope Summary

| Scope       | Administrative Rights Required | Visible To                |
| ----------- | ------------------------------ | ------------------------- |
| CurrentUser | No                             | Current user only         |
| AllUsers    | Yes                            | All users on the computer |

For most scenarios, the recommended installation method is:

```powershell
Install-Module PasswordGen.PS -Scope CurrentUser
```

or, for offline environments:

```powershell
.\installOffline.ps1
```
