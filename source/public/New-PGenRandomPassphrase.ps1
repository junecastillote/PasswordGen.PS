function New-PGenRandomPassphrase {
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
        else {
            Write-Debug "Word count loaded from source: $($words.Count)"
            Write-Debug "Random word = $($words[$([System.Security.Cryptography.RandomNumberGenerator]::GetInt32(0,($words.count - 1)))])"
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

            if ($AddNumber) {
                $numberCharacters =
                New-Object 'System.Collections.Generic.List[char]'

                for (
                    $numberIndex = 0
                    $numberIndex -lt $NumberLength
                    $numberIndex++
                ) {
                    $numberCharacters.Add(
                        (
                            Get-CryptoRandomCharacter `
                                -CharacterPool '0123456789'
                        )
                    )
                }

                $numberValue = -join $numberCharacters
                $passphraseParts.Add($numberValue)
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

                return [pscustomobject][ordered]@{
                    Passphrase           = $passphrase
                    Length               = $passphrase.Length
                    WordCount            = $selectedWords.Count
                    Words                = $selectedWords.ToArray()
                    Separator            = $Separator
                    WordsCapitalized     = [bool]$CapitalizeWords
                    NumberAdded          = [bool]$AddNumber
                    NumberLength         = $effectiveNumberLength
                    NumberValue          = $numberValue
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