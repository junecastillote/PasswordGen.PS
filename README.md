# PasswordGen.PS

PowerShell module for generating cryptographically secure passwords and passphrases.

## Features

### Password Generation

Generate random passwords using configurable character sets:

- Uppercase letters
- Lowercase letters
- Numbers
- Special characters
- Minimum numeric requirements
- Minimum special character requirements
- Ambiguous character exclusion
- Clipboard support
- SecureString output
- Metadata output

### Passphrase Generation

Generate memorable passphrases using the EFF Large Word List:

- Configurable word count
- Configurable separators
- Optional word capitalization
- Optional numeric suffix generation
- Clipboard support
- SecureString output
- Metadata output

## Requirements

### Windows

- Windows PowerShell 5.1
- PowerShell 7+

### Non-Windows

- PowerShell 7+

## Installation

### PowerShell Gallery

```powershell
Install-Module PasswordGen.PS
```

### Offline Installation

Download the release package and run:

```powershell
.\installOffline.ps1
```

For CurrentUser scope:

```powershell
.\installOffline.ps1 -Scope CurrentUser
```

For AllUsers scope:

```powershell
.\installOffline.ps1 -Scope AllUsers
```

## Quick Start

### Generate a Password

```powershell
New-PGenRandomPassword
```

Example:

```text
gE@8Qw2m#aY6Tz3L
```

### Generate a Longer Password

```powershell
New-PGenRandomPassword `
    -Length 24
```

### Exclude Ambiguous Characters

```powershell
New-PGenRandomPassword `
    -NoAmbiguousCharacters
```

### Generate a Passphrase

```powershell
New-PGenRandomPassphrase
```

Example:

```text
grudge-smuggler-symphonic-squeegee
```

### Capitalized Passphrase

```powershell
New-PGenRandomPassphrase `
    -CapitalizeWords
```

Example:

```text
Grudge-Smuggler-Symphonic-Squeegee
```

### Passphrase with Numeric Suffix

```powershell
New-PGenRandomPassphrase `
    -AddNumber
```

Example:

```text
Grudge36-Smuggler-Symphonic-Squeegee
```

## Functions

| Function                   | Description                                                                  |
| -------------------------- | ---------------------------------------------------------------------------- |
| `New-PGenRandomPassword`   | Generates cryptographically secure random passwords                          |
| `New-PGenRandomPassphrase` | Generates cryptographically secure passphrases using the EFF Large Word List |

## Documentation

- [INSTALLATION.md](docs/INSTALLATION.md)
- [PASSWORDS.md](docs/PASSWORDS.md)
- [PASSPHRASES.md](docs/PASSPHRASES.md)

## License

[MIT License](LICENSE)
