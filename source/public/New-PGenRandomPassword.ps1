function New-PGenRandomPassword {
    <#
    .SYNOPSIS
    Generates a cryptographically secure random password.

    .DESCRIPTION
    Generates a random password using configurable character sets and
    cryptographically secure random number generation provided by
    System.Security.Cryptography.RandomNumberGenerator.

    By default, uppercase letters, lowercase letters, numbers, and special
    characters are enabled.

    The function guarantees that the resulting password contains at least one
    character from every enabled character set. Additional minimum numeric and
    special character requirements may also be specified.

    The generated password can optionally be copied to the clipboard, returned
    as a SecureString, or returned as a metadata object containing password
    statistics and generation details.

    .PARAMETER Length
    Specifies the total length of the password.

    The minimum allowable length is determined dynamically based on the enabled
    character sets and any minimum character requirements.

    Default: 16

    .PARAMETER Uppercase
    Enables uppercase letters (A-Z).

    Default: $true

    .PARAMETER Lowercase
    Enables lowercase letters (a-z).

    Default: $true

    .PARAMETER Numbers
    Enables numeric characters (0-9).

    Default: $true

    If MinimumNumbers is greater than zero, the numeric character set is
    automatically enabled regardless of this setting.

    .PARAMETER Special
    Enables special characters.

    Default: $true

    If MinimumSpecial is greater than zero, the special character set is
    automatically enabled regardless of this setting.

    .PARAMETER MinimumNumbers
    Specifies the minimum number of numeric characters required in the
    generated password.

    A value greater than zero automatically enables the Numbers character set.

    Default: 0

    .PARAMETER MinimumSpecial
    Specifies the minimum number of special characters required in the
    generated password.

    A value greater than zero automatically enables the Special character set.

    Default: 0

    .PARAMETER SpecialCharacters
    Specifies the set of special characters that may be used when the Special
    character set is enabled.

    Duplicate characters are automatically removed.

    Default:

    !@#$%^&*

    .PARAMETER NoAmbiguousCharacters
    Excludes commonly confused characters from the generated password.

    Excluded characters:

    Uppercase:
        I O

    Lowercase:
        l

    Numbers:
        0 1

    .PARAMETER CopyToClipboard
    Copies the generated plaintext password to the system clipboard.

    The password is still returned to the pipeline.

    .PARAMETER AsSecureString
    Returns the generated password as a SecureString.

    This parameter cannot be used together with PassThruObject.

    .PARAMETER PassThruObject
    Returns a PSCustomObject containing the generated password and additional
    metadata including character counts, entropy estimate, and generation
    options.

    This parameter cannot be used together with AsSecureString.

    .OUTPUTS
    System.String

    Returned by default.

    .OUTPUTS
    System.Security.SecureString

    Returned when AsSecureString is specified.

    .OUTPUTS
    System.Management.Automation.PSCustomObject

    Returned when PassThruObject is specified.

    .EXAMPLE
    New-PGenRandomPassword

    Generates a 16-character password using all default character sets.

    .EXAMPLE
    New-PGenRandomPassword -Length 24

    Generates a 24-character password using all default character sets.

    .EXAMPLE
    New-PGenRandomPassword `
        -Length 20 `
        -MinimumNumbers 3 `
        -MinimumSpecial 2

    Generates a 20-character password containing at least three numbers and
    at least two special characters.

    .EXAMPLE
    New-PGenRandomPassword `
        -Length 20 `
        -NoAmbiguousCharacters

    Generates a password that excludes visually ambiguous characters such as
    I, O, l, 0, and 1.

    .EXAMPLE
    New-PGenRandomPassword `
        -Uppercase:$false `
        -Lowercase:$true `
        -Numbers:$true `
        -Special:$false `
        -Length 16

    Generates a password using only lowercase letters and numbers.

    .EXAMPLE
    New-PGenRandomPassword `
        -Length 32 `
        -CopyToClipboard

    Generates a password and copies it to the clipboard.

    .EXAMPLE
    New-PGenRandomPassword `
        -Length 32 `
        -AsSecureString

    Generates a password and returns it as a SecureString.

    .EXAMPLE
    New-PGenRandomPassword `
        -Length 24 `
        -MinimumNumbers 2 `
        -MinimumSpecial 2 `
        -PassThruObject

    Returns an object similar to:

    Password               : Tm!4qN3@Lc2hRw8#Jf6DpXaK
    Length                 : 24
    ContainsUppercase      : True
    ContainsLowercase      : True
    ContainsNumbers        : True
    ContainsSpecial        : True
    UppercaseCount         : 9
    LowercaseCount         : 8
    NumberCount            : 4
    SpecialCount           : 3
    MinimumNumbers         : 2
    MinimumSpecial         : 2
    AmbiguousCharsExcluded : False
    CharacterPoolSize      : 70
    PoolBasedEntropyBits   : 147.09
    CopiedToClipboard      : False

    .NOTES
    Character requirements are guaranteed through explicit character
    allocation followed by a cryptographically secure Fisher-Yates shuffle.

    Random values are generated using
    System.Security.Cryptography.RandomNumberGenerator rather than Get-Random.

    Compatible with:
    - Windows PowerShell 5.1
    - PowerShell 7+

    .LINK
    https://github.com/junecastillote/PasswordGen.PS
    #>

    [CmdletBinding()]
    [OutputType(
        [string],
        [System.Security.SecureString],
        [System.Management.Automation.PSCustomObject]
    )]
    param (
        [Parameter()]
        [ValidateRange(1, 4096)]
        [int]$Length = 16,

        [Parameter()]
        [bool]$Uppercase = $true,

        [Parameter()]
        [bool]$Lowercase = $true,

        [Parameter()]
        [bool]$Numbers = $true,

        [Parameter()]
        [bool]$Special = $true,

        [Parameter()]
        [ValidateRange(0, 4096)]
        [int]$MinimumNumbers = 0,

        [Parameter()]
        [ValidateRange(0, 4096)]
        [int]$MinimumSpecial = 0,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$SpecialCharacters = '!@#$%^&*',

        [Parameter()]
        [switch]$NoAmbiguousCharacters,

        [Parameter()]
        [switch]$CopyToClipboard,

        [Parameter()]
        [switch]$AsSecureString,

        [Parameter()]
        [switch]$PassThruObject
    )

    begin {
        if ($AsSecureString -and $PassThruObject) {
            throw 'AsSecureString and PassThruObject cannot be used together.'
        }

        # A positive minimum automatically enables its corresponding set.
        $numbersEnabled = $Numbers -or ($MinimumNumbers -gt 0)
        $specialEnabled = $Special -or ($MinimumSpecial -gt 0)

        # Remove duplicate special characters to avoid accidental weighting.
        $normalizedSpecialCharacters = -join (
            $SpecialCharacters.ToCharArray() |
            Select-Object -Unique
        )

        $characterSets = [ordered]@{
            Uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
            Lowercase = 'abcdefghijklmnopqrstuvwxyz'
            Numbers   = '0123456789'
            Special   = $normalizedSpecialCharacters
        }

        if ($NoAmbiguousCharacters) {
            $characterSets.Uppercase = $characterSets.Uppercase -replace '[IO]', ''
            $characterSets.Lowercase = $characterSets.Lowercase -replace 'l', ''
            $characterSets.Numbers = $characterSets.Numbers -replace '[01]', ''
        }

        # Keep character categories distinct. This ensures that one character
        # cannot satisfy both a special-character requirement and an
        # alphanumeric requirement.
        if ($specialEnabled) {
            $nonSpecialCharacters = (
                $characterSets.Uppercase +
                $characterSets.Lowercase +
                $characterSets.Numbers
            ).ToCharArray()

            $overlappingSpecialCharacters = @(
                $characterSets.Special.ToCharArray() |
                Where-Object {
                    $nonSpecialCharacters -contains $_
                } |
                Select-Object -Unique
            )

            if ($overlappingSpecialCharacters.Count -gt 0) {
                $overlapText = -join $overlappingSpecialCharacters

                throw (
                    'SpecialCharacters cannot contain characters from the ' +
                    'uppercase, lowercase, or numeric sets. ' +
                    "Overlapping characters: $overlapText"
                )
            }
        }

        $enabledSets = New-Object 'System.Collections.Generic.List[object]'

        if ($Uppercase) {
            $enabledSets.Add(
                [pscustomobject]@{
                    Name       = 'Uppercase'
                    Characters = $characterSets.Uppercase
                    Minimum    = 1
                }
            )
        }

        if ($Lowercase) {
            $enabledSets.Add(
                [pscustomobject]@{
                    Name       = 'Lowercase'
                    Characters = $characterSets.Lowercase
                    Minimum    = 1
                }
            )
        }

        if ($numbersEnabled) {
            $enabledSets.Add(
                [pscustomobject]@{
                    Name       = 'Numbers'
                    Characters = $characterSets.Numbers
                    Minimum    = [System.Math]::Max(
                        1,
                        $MinimumNumbers
                    )
                }
            )
        }

        if ($specialEnabled) {
            $enabledSets.Add(
                [pscustomobject]@{
                    Name       = 'Special'
                    Characters = $characterSets.Special
                    Minimum    = [System.Math]::Max(
                        1,
                        $MinimumSpecial
                    )
                }
            )
        }

        if ($enabledSets.Count -eq 0) {
            throw @'
At least one character set must be enabled. Enable Uppercase, Lowercase,
Numbers, or Special.
'@
        }

        foreach ($set in $enabledSets) {
            if ([string]::IsNullOrEmpty($set.Characters)) {
                throw "The enabled '$($set.Name)' character set is empty."
            }
        }

        $minimumRequiredLength = 0

        foreach ($set in $enabledSets) {
            $minimumRequiredLength += $set.Minimum
        }

        if ($Length -lt $minimumRequiredLength) {
            $requirementSummary = @(
                $enabledSets |
                ForEach-Object {
                    '{0}={1}' -f $_.Name, $_.Minimum
                }
            )

            $message = @(
                "Length must be at least $minimumRequiredLength for the current requirements."
                "Current requirements: $($requirementSummary -join ', ')."
            ) -join ' '

            throw $message
        }

        $combinedPool = -join (
            $enabledSets |
            ForEach-Object {
                $_.Characters
            }
        )

        # Remove duplicate characters from the final combined pool.
        $combinedPool = -join (
            $combinedPool.ToCharArray() |
            Select-Object -Unique
        )

        if ([string]::IsNullOrEmpty($combinedPool)) {
            throw 'The combined character pool is empty.'
        }

        $randomNumberGenerator =
        [System.Security.Cryptography.RandomNumberGenerator]::Create()

        function Get-CryptoRandomIndex {
            [CmdletBinding()]
            [OutputType([int])]
            param (
                [Parameter(Mandatory)]
                [ValidateRange(1, 2147483647)]
                [int]$UpperBound
            )

            if ($UpperBound -eq 1) {
                return 0
            }

            # Use rejection sampling to avoid modulo bias.
            $byteBuffer = New-Object 'byte[]' 4
            $range = [uint64]1 + [uint64][uint32]::MaxValue
            $acceptedRange = $range - ($range % [uint64]$UpperBound)

            do {
                $randomNumberGenerator.GetBytes($byteBuffer)

                $randomValue = [uint64][BitConverter]::ToUInt32(
                    $byteBuffer,
                    0
                )
            }
            while ($randomValue -ge $acceptedRange)

            return $randomValue % [uint64]$UpperBound
        }

        function Get-CryptoRandomCharacter {
            [CmdletBinding()]
            [OutputType([char])]
            param (
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string]$CharacterPool
            )

            $randomIndex = Get-CryptoRandomIndex `
                -UpperBound $CharacterPool.Length

            return $CharacterPool[$randomIndex]
        }
    }

    process {
        try {
            $passwordCharacters =
            New-Object 'System.Collections.Generic.List[char]'

            # Add the required number of characters from each enabled set.
            foreach ($set in $enabledSets) {
                for ($index = 0; $index -lt $set.Minimum; $index++) {
                    $randomCharacter = Get-CryptoRandomCharacter `
                        -CharacterPool $set.Characters

                    $passwordCharacters.Add($randomCharacter)
                }
            }

            # Fill remaining positions from the complete enabled pool.
            while ($passwordCharacters.Count -lt $Length) {

                $randomCharacter = Get-CryptoRandomCharacter -CharacterPool $combinedPool

                $passwordCharacters.Add($randomCharacter)
            }

            # Apply a cryptographically secure Fisher-Yates shuffle.
            for (
                $currentIndex = $passwordCharacters.Count - 1
                $currentIndex -gt 0
                $currentIndex--
            ) {
                $swapIndex = Get-CryptoRandomIndex `
                    -UpperBound ($currentIndex + 1)

                $temporaryCharacter =
                $passwordCharacters[$currentIndex]

                $passwordCharacters[$currentIndex] =
                $passwordCharacters[$swapIndex]

                $passwordCharacters[$swapIndex] =
                $temporaryCharacter
            }

            $password = -join $passwordCharacters

            if ($CopyToClipboard) {
                $setClipboardCommand = Get-Command `
                    -Name 'Set-Clipboard' `
                    -ErrorAction SilentlyContinue

                if (-not $setClipboardCommand) {
                    throw @'
CopyToClipboard was specified, but Set-Clipboard is not available in the
current PowerShell session.
'@
                }

                Set-Clipboard `
                    -Value $password `
                    -ErrorAction Stop
            }

            if ($AsSecureString) {
                return ConvertTo-SecureString `
                    -String $password `
                    -AsPlainText `
                    -Force
            }

            if ($PassThruObject) {
                $poolBasedEntropy = [System.Math]::Round(
                    $Length * [System.Math]::Log(
                        $combinedPool.Length,
                        2
                    ),
                    2
                )

                $actualUppercaseCount = 0
                $actualLowercaseCount = 0
                $actualNumberCount = 0
                $actualSpecialCount = 0

                foreach ($passwordCharacter in $password.ToCharArray()) {
                    if (
                        $characterSets.Uppercase.IndexOf(
                            $passwordCharacter
                        ) -ge 0
                    ) {
                        $actualUppercaseCount++
                    }
                    elseif (
                        $characterSets.Lowercase.IndexOf(
                            $passwordCharacter
                        ) -ge 0
                    ) {
                        $actualLowercaseCount++
                    }
                    elseif (
                        $characterSets.Numbers.IndexOf(
                            $passwordCharacter
                        ) -ge 0
                    ) {
                        $actualNumberCount++
                    }
                    elseif (
                        $characterSets.Special.IndexOf(
                            $passwordCharacter
                        ) -ge 0
                    ) {
                        $actualSpecialCount++
                    }
                }

                $effectiveMinimumNumbers = 0

                if ($numbersEnabled) {
                    $effectiveMinimumNumbers = [System.Math]::Max(
                        1,
                        $MinimumNumbers
                    )
                }

                $effectiveMinimumSpecial = 0

                if ($specialEnabled) {
                    $effectiveMinimumSpecial = [System.Math]::Max(
                        1,
                        $MinimumSpecial
                    )
                }

                return [pscustomobject][ordered]@{
                    Password               = $password
                    Length                 = $password.Length
                    ContainsUppercase      = ($actualUppercaseCount -gt 0)
                    ContainsLowercase      = ($actualLowercaseCount -gt 0)
                    ContainsNumbers        = ($actualNumberCount -gt 0)
                    ContainsSpecial        = ($actualSpecialCount -gt 0)
                    UppercaseCount         = $actualUppercaseCount
                    LowercaseCount         = $actualLowercaseCount
                    NumberCount            = $actualNumberCount
                    SpecialCount           = $actualSpecialCount
                    MinimumNumbers         = $effectiveMinimumNumbers
                    MinimumSpecial         = $effectiveMinimumSpecial
                    AmbiguousCharsExcluded = [bool]$NoAmbiguousCharacters
                    CharacterPoolSize      = $combinedPool.Length
                    PoolBasedEntropyBits   = $poolBasedEntropy
                    CopiedToClipboard      = [bool]$CopyToClipboard
                }
            }

            return $password
        }
        finally {
            # This clears the local reference but cannot guarantee removal
            # of every immutable string copy from process memory.
            $password = $null
        }
    }

    end {
        if ($null -ne $randomNumberGenerator) {
            $randomNumberGenerator.Dispose()
        }
    }
}