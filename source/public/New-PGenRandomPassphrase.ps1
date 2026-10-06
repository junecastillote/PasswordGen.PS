function New-PGenRandomPassphrase {
    <#
.SYNOPSIS
Generates a cryptographically secure random passphrase.

.DESCRIPTION
Generates a random passphrase from the EFF Large Word List loaded by the
PasswordGen.PS module.

Words are selected using a cryptographically secure random number generator
and words are not repeated within a single passphrase.

Optional features include word capitalization, numeric suffix generation,
clipboard copying, SecureString output, and metadata output.

The default passphrase contains four randomly selected words separated by
a hyphen (-).

.PARAMETER WordCount
Specifies the number of words to include in the generated passphrase.

Default: 4

.PARAMETER Separator
Specifies the separator inserted between words.

Default: -

Examples:

-
_
.
@

.PARAMETER CapitalizeWords
Converts each selected word to title case.

Example:

Forest-Lantern-Silver-Ocean

.PARAMETER AddNumber
Appends a randomly generated numeric component to the passphrase.

Example:

Forest-Lantern-Silver-Ocean-42

.PARAMETER NumberLength
Specifies the number of digits to generate when AddNumber is specified.

Default: 2

.PARAMETER CopyToClipboard
Copies the generated passphrase to the clipboard.

The passphrase is still returned to the pipeline.

.PARAMETER AsSecureString
Returns the generated passphrase as a SecureString.

This parameter cannot be used together with PassThruObject.

.PARAMETER PassThruObject
Returns a PSCustomObject containing the generated passphrase and
additional metadata.

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
New-PGenRandomPassphrase

Example output:

forest-lantern-silver-ocean

.EXAMPLE
New-PGenRandomPassphrase -WordCount 6

Example output:

forest-lantern-silver-ocean-river-anchor

.EXAMPLE
New-PGenRandomPassphrase -CapitalizeWords

Example output:

Forest-Lantern-Silver-Ocean

.EXAMPLE
New-PGenRandomPassphrase `
    -Separator '_'

Example output:

forest_lantern_silver_ocean

.EXAMPLE
New-PGenRandomPassphrase `
    -AddNumber

Example output:

forest-lantern-silver-ocean-42

.EXAMPLE
New-PGenRandomPassphrase `
    -AddNumber `
    -NumberLength 4

Example output:

forest-lantern-silver-ocean-4829

.EXAMPLE
New-PGenRandomPassphrase `
    -CapitalizeWords `
    -AddNumber `
    -PassThruObject

Returns an object similar to:

Passphrase           : Forest-Lantern-Silver-Ocean-42
Length               : 32
WordCount            : 4
Words                : {Forest, Lantern, Silver, Ocean}
Separator            : -
WordsCapitalized     : True
NumberAdded          : True
NumberLength         : 2
NumberValue          : 42
WordListSize         : 7776
WordListSource       : EFF Large Word List
EstimatedEntropyBits : 58.34
CopiedToClipboard    : False

.EXAMPLE
New-PGenRandomPassphrase `
    -CopyToClipboard

Generates a passphrase and copies it to the clipboard.

.EXAMPLE
New-PGenRandomPassphrase `
    -AsSecureString

Generates a passphrase and returns it as a SecureString.

.NOTES
Words are selected from the EFF Large Word List loaded during module
import.

Passphrases are generated using
System.Security.Cryptography.RandomNumberGenerator.

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
        [ValidateRange(2, 50)]
        [int]$WordCount = 4,

        [Parameter()]
        [AllowEmptyString()]
        [string]$Separator = '-',

        [Parameter()]
        [switch]$CapitalizeWords,

        [Parameter()]
        [switch]$AddNumber,

        [Parameter()]
        [ValidateRange(1, 32)]
        [int]$NumberLength = 2,

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

        $words = $script:PGenWordList

        if ($null -eq $words -or $words.Count -eq 0) {

            throw (
                'The module word list was not loaded or has (0) usable words.'
            )
        }

        if ($words.Count -lt $WordCount) {
            throw (
                "The word list contains only $($words.Count) unique words, " +
                "but WordCount requires $WordCount unique words."
            )
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

            $byteBuffer = New-Object 'byte[]' 4

            $range =
            [uint64]1 + [uint64][uint32]::MaxValue

            $acceptedRange =
            $range - ($range % [uint64]$UpperBound)

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
            $availableWords =
            New-Object 'System.Collections.Generic.List[string]'

            foreach ($word in $words) {
                $availableWords.Add($word)
            }

            $selectedWords =
            New-Object 'System.Collections.Generic.List[string]'

            for (
                $wordIndex = 0
                $wordIndex -lt $WordCount
                $wordIndex++
            ) {
                $selectedIndex = Get-CryptoRandomIndex `
                    -UpperBound $availableWords.Count

                $selectedWord = $availableWords[$selectedIndex]

                if ($CapitalizeWords) {
                    $selectedWord = (
                        [System.Globalization.CultureInfo]::InvariantCulture
                    ).TextInfo.ToTitleCase(
                        $selectedWord.ToLowerInvariant()
                    )
                }

                $selectedWords.Add($selectedWord)

                # Remove the selected word so that words cannot repeat.
                $availableWords.RemoveAt($selectedIndex)
            }

            $passphraseParts =
            New-Object 'System.Collections.Generic.List[string]'

            foreach ($selectedWord in $selectedWords) {
                $passphraseParts.Add($selectedWord)
            }

            $numberValue = $null
            $numberWordIndex = $null

            if ($AddNumber) {
                $numberCharacters =
                New-Object 'System.Collections.Generic.List[char]'

                for (
                    $numberIndex = 0
                    $numberIndex -lt $NumberLength
                    $numberIndex++
                ) {
                    $randomNumberCharacter = Get-CryptoRandomCharacter `
                        -CharacterPool '0123456789'

                    $numberCharacters.Add($randomNumberCharacter)
                }

                $numberValue = -join $numberCharacters

                # Select one of the passphrase words and append the number.
                $numberWordIndex = Get-CryptoRandomIndex `
                    -UpperBound $passphraseParts.Count

                $passphraseParts[$numberWordIndex] = (
                    $passphraseParts[$numberWordIndex] +
                    $numberValue
                )
            }

            $passphrase = $passphraseParts -join $Separator

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
                    -Value $passphrase `
                    -ErrorAction Stop
            }

            if ($AsSecureString) {
                return ConvertTo-SecureString `
                    -String $passphrase `
                    -AsPlainText `
                    -Force
            }

            if ($PassThruObject) {
                $wordEntropyBits = (
                    $WordCount *
                    [System.Math]::Log($words.Count, 2)
                )

                $numberEntropyBits = 0

                if ($AddNumber) {
                    $numberEntropyBits = (
                        $NumberLength *
                        [System.Math]::Log(10, 2)
                    )
                }

                $estimatedEntropyBits = [System.Math]::Round(
                    (
                        $wordEntropyBits +
                        $numberEntropyBits
                    ),
                    2
                )

                $effectiveNumberLength = 0

                if ($AddNumber) {
                    $effectiveNumberLength = $NumberLength
                }

                $numberWordPosition = $null

                if ($AddNumber) {
                    $numberWordPosition = $numberWordIndex + 1
                }

                return [pscustomobject][ordered]@{
                    Passphrase           = $passphrase
                    Length               = $passphrase.Length
                    WordCount            = $selectedWords.Count
                    Words                = $selectedWords.ToArray()
                    PassphraseParts      = $passphraseParts.ToArray()
                    Separator            = $Separator
                    WordsCapitalized     = [bool]$CapitalizeWords
                    NumberAdded          = [bool]$AddNumber
                    NumberLength         = $effectiveNumberLength
                    NumberValue          = $numberValue
                    NumberWordIndex      = $numberWordIndex
                    NumberWordPosition   = $numberWordPosition
                    WordListSize         = $words.Count
                    WordListSource       = 'EFF Large Word List'
                    EstimatedEntropyBits = $estimatedEntropyBits
                    CopiedToClipboard    = [bool]$CopyToClipboard
                }
            }

            return $passphrase
        }
        finally {
            $passphrase = $null
            $numberValue = $null
        }
    }

    end {
        if ($null -ne $randomNumberGenerator) {
            $randomNumberGenerator.Dispose()
        }
    }
}