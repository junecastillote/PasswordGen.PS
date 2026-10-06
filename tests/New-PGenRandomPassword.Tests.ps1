#Requires -Version 5.1
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $functionPath = Join-Path -Path $PSScriptRoot -ChildPath (
        '../source/public/New-PGenRandomPassword.ps1'
    )

    $resolvedFunctionPath = Resolve-Path `
        -Path $functionPath `
        -ErrorAction Stop

    . $resolvedFunctionPath.Path
}

Describe 'New-PGenRandomPassword' {

    Context 'Function availability' {

        It 'Loads the New-PGenRandomPassword function' {
            Get-Command `
                -name 'New-PGenRandomPassword' `
                -CommandType Function `
                -ErrorAction SilentlyContinue |
            Should -Not -BeNullOrEmpty
        }
    }

    Context 'Default behavior' {

        It 'Generates a 16-character password using defaults' {
            $result = New-PGenRandomPassword

            $result | Should -BeOfType [string]
            $result.Length | Should -Be 16
        }

        It 'Contains all default character classes' {
            $result = New-PGenRandomPassword

            $result | Should -Match '[A-Z]'
            $result | Should -Match '[a-z]'
            $result | Should -Match '[0-9]'
            $result | Should -Match '[!@#$%^&*]'
        }

        It 'Generates different passwords across two calls' {
            $firstPassword = New-PGenRandomPassword
            $secondPassword = New-PGenRandomPassword

            $firstPassword | Should -Not -Be $secondPassword
        }
    }

    Context 'Length parameter' {

        It 'Generates a password of the requested length' {
            $result = New-PGenRandomPassword -Length 24

            $result.Length | Should -Be 24
        }

        It 'Generates a one-character password when one set is enabled' {
            $result = New-PGenRandomPassword `
                -Length 1 `
                -Uppercase:$false `
                -Lowercase:$false `
                -Numbers:$true `
                -Special:$false

            $result.Length | Should -Be 1
            $result | Should -Match '^[0-9]$'
        }

        It 'Generates a long password of the requested length' {
            $result = New-PGenRandomPassword -Length 256

            $result.Length | Should -Be 256
        }
    }

    Context 'Minimum character requirements' {

        It 'Honors the MinimumNumbers requirement' {
            $password = New-PGenRandomPassword `
                -Length 20 `
                -MinimumNumbers 3

            $numberCount = (
                [regex]::Matches($password, '[0-9]')
            ).Count

            $numberCount | Should -BeGreaterOrEqual 3
        }

        It 'Honors the MinimumSpecial requirement' {
            $password = New-PGenRandomPassword `
                -Length 20 `
                -MinimumSpecial 2

            $specialCount = (
                [regex]::Matches(
                    $password,
                    '[!@#$%^&*]'
                )
            ).Count

            $specialCount | Should -BeGreaterOrEqual 2
        }

        It 'Honors numeric and special minimums simultaneously' {
            $password = New-PGenRandomPassword `
                -Length 20 `
                -MinimumNumbers 3 `
                -MinimumSpecial 2

            $numberCount = (
                [regex]::Matches($password, '[0-9]')
            ).Count

            $specialCount = (
                [regex]::Matches(
                    $password,
                    '[!@#$%^&*]'
                )
            ).Count

            $numberCount | Should -BeGreaterOrEqual 3
            $specialCount | Should -BeGreaterOrEqual 2
        }

        It 'Generates the exact minimum valid length' {
            $password = New-PGenRandomPassword `
                -Length 7 `
                -Uppercase:$true `
                -Lowercase:$true `
                -Numbers:$true `
                -Special:$true `
                -MinimumNumbers 3 `
                -MinimumSpecial 2

            $password.Length | Should -Be 7

            (
                [regex]::Matches($password, '[0-9]')
            ).Count | Should -BeGreaterOrEqual 3

            (
                [regex]::Matches(
                    $password,
                    '[!@#$%^&*]'
                )
            ).Count | Should -BeGreaterOrEqual 2
        }
    }

    Context 'Automatic character-set enablement' {

        It 'Automatically enables Numbers when MinimumNumbers is positive' {
            $password = New-PGenRandomPassword `
                -Length 10 `
                -Uppercase:$false `
                -Lowercase:$false `
                -Numbers:$false `
                -Special:$false `
                -MinimumNumbers 3

            $numberCount = (
                [regex]::Matches($password, '[0-9]')
            ).Count

            $password | Should -Match '^[0-9]+$'
            $numberCount | Should -BeGreaterOrEqual 3
        }

        It 'Automatically enables Special when MinimumSpecial is positive' {
            $password = New-PGenRandomPassword `
                -Length 10 `
                -Uppercase:$false `
                -Lowercase:$false `
                -Numbers:$false `
                -Special:$false `
                -MinimumSpecial 3

            $specialCount = (
                [regex]::Matches(
                    $password,
                    '[!@#$%^&*]'
                )
            ).Count

            $password | Should -Match '^[!@#$%^&*]+$'
            $specialCount | Should -BeGreaterOrEqual 3
        }

        It 'Automatically enables Numbers and Special when both minimums are positive' {
            $password = New-PGenRandomPassword `
                -Length 10 `
                -Uppercase:$false `
                -Lowercase:$false `
                -Numbers:$false `
                -Special:$false `
                -MinimumNumbers 2 `
                -MinimumSpecial 2

            $numberCount = (
                [regex]::Matches($password, '[0-9]')
            ).Count

            $specialCount = (
                [regex]::Matches(
                    $password,
                    '[!@#$%^&*]'
                )
            ).Count

            $password | Should -Match '^[0-9!@#$%^&*]+$'
            $numberCount | Should -BeGreaterOrEqual 2
            $specialCount | Should -BeGreaterOrEqual 2
        }
    }

    Context 'Ambiguous character handling' {

        It 'Does not generate ambiguous characters when requested' {
            $password = New-PGenRandomPassword `
                -Length 100 `
                -NoAmbiguousCharacters

            $password | Should -Not -MatchExactly '[IOl01]'
        }

        It 'Reports that ambiguous characters were excluded' {
            $result = New-PGenRandomPassword `
                -NoAmbiguousCharacters `
                -PassThruObject

            $result.AmbiguousCharsExcluded | Should -BeTrue
        }

        It 'Uses the expected reduced pool size with default sets' {
            $result = New-PGenRandomPassword `
                -NoAmbiguousCharacters `
                -PassThruObject

            # Default pool:
            # 26 uppercase + 26 lowercase + 10 numbers + 8 special = 70
            #
            # Removed:
            # Uppercase I and O, lowercase l, numbers 0 and 1 = 5
            $result.CharacterPoolSize | Should -Be 65
        }
    }

    Context 'Character-set selection' {

        It 'Generates lowercase and numeric characters only' {
            $password = New-PGenRandomPassword `
                -Length 50 `
                -Uppercase:$false `
                -Lowercase:$true `
                -Numbers:$true `
                -Special:$false

            $password | Should -MatchExactly '^[a-z0-9]+$'
            $password | Should -MatchExactly '[a-z]'
            $password | Should -Match '[0-9]'
            $password | Should -Not -MatchExactly '[A-Z]'
            $password | Should -Not -Match '[!@#$%^&*]'
        }

        It 'Generates uppercase characters only' {
            $password = New-PGenRandomPassword `
                -Length 50 `
                -Uppercase:$true `
                -Lowercase:$false `
                -Numbers:$false `
                -Special:$false

            $password | Should -MatchExactly '^[A-Z]+$'
        }

        It 'Generates lowercase characters only' {
            $password = New-PGenRandomPassword `
                -Length 50 `
                -Uppercase:$false `
                -Lowercase:$true `
                -Numbers:$false `
                -Special:$false

            $password | Should -MatchExactly '^[a-z]+$'
        }

        It 'Generates numeric characters only' {
            $password = New-PGenRandomPassword `
                -Length 50 `
                -Uppercase:$false `
                -Lowercase:$false `
                -Numbers:$true `
                -Special:$false

            $password | Should -Match '^[0-9]+$'
        }

        It 'Generates special characters only' {
            $password = New-PGenRandomPassword `
                -Length 50 `
                -Uppercase:$false `
                -Lowercase:$false `
                -Numbers:$false `
                -Special:$true

            $password | Should -Match '^[!@#$%^&*]+$'
        }
    }

    Context 'Custom special characters' {

        It 'Accepts a valid custom special-character set' {
            {
                New-PGenRandomPassword `
                    -Length 20 `
                    -SpecialCharacters '_+-='
            } | Should -Not -Throw
        }

        It 'Uses only the configured custom special characters' {
            $password = New-PGenRandomPassword `
                -Length 50 `
                -Uppercase:$false `
                -Lowercase:$false `
                -Numbers:$false `
                -Special:$true `
                -SpecialCharacters '_+-='

            $password | Should -Match '^[_+=-]+$'
        }

        It 'Honors MinimumSpecial with a custom special-character set' {
            $password = New-PGenRandomPassword `
                -Length 20 `
                -MinimumSpecial 5 `
                -SpecialCharacters '_+-='

            $customSpecialCount = (
                [regex]::Matches(
                    $password,
                    '[_+=-]'
                )
            ).Count

            $customSpecialCount | Should -BeGreaterOrEqual 5
        }

        It 'Removes duplicate custom special characters' {
            $result = New-PGenRandomPassword `
                -Length 20 `
                -Uppercase:$false `
                -Lowercase:$false `
                -Numbers:$false `
                -Special:$true `
                -SpecialCharacters '!!!!@@@@####' `
                -PassThruObject

            $result.CharacterPoolSize | Should -Be 3
            $result.Password | Should -Match '^[!@#]+$'
        }

        It 'Rejects uppercase characters in SpecialCharacters' {
            {
                New-PGenRandomPassword `
                    -SpecialCharacters '!@A'
            } | Should -Throw
        }

        It 'Rejects lowercase characters in SpecialCharacters' {
            {
                New-PGenRandomPassword `
                    -SpecialCharacters '!@a'
            } | Should -Throw
        }

        It 'Rejects numeric characters in SpecialCharacters' {
            {
                New-PGenRandomPassword `
                    -SpecialCharacters '!@1'
            } | Should -Throw
        }
    }

    Context 'SecureString output' {

        It 'Returns a SecureString when AsSecureString is specified' {
            $result = New-PGenRandomPassword -AsSecureString

            $result |
            Should -BeOfType [System.Security.SecureString]
        }

        It 'Does not return a plaintext string with AsSecureString' {
            $result = New-PGenRandomPassword -AsSecureString

            $result |
            Should -Not -BeOfType [string]
        }
    }

    Context 'PassThruObject output' {

        It 'Returns a PSCustomObject when PassThruObject is specified' {
            $result = New-PGenRandomPassword -PassThruObject

            $result |
            Should -BeOfType [System.Management.Automation.PSCustomObject]
        }

        It 'Returns all expected metadata properties' {
            $result = New-PGenRandomPassword -PassThruObject

            $expectedProperties = @(
                'Password'
                'Length'
                'ContainsUppercase'
                'ContainsLowercase'
                'ContainsNumbers'
                'ContainsSpecial'
                'UppercaseCount'
                'LowercaseCount'
                'NumberCount'
                'SpecialCount'
                'MinimumNumbers'
                'MinimumSpecial'
                'AmbiguousCharsExcluded'
                'CharacterPoolSize'
                'PoolBasedEntropyBits'
                'CopiedToClipboard'
            )

            foreach ($propertyName in $expectedProperties) {
                $result.PSObject.Properties.Name |
                Should -Contain $propertyName
            }
        }

        It 'Returns length metadata matching the actual password length' {
            $result = New-PGenRandomPassword `
                -Length 32 `
                -PassThruObject

            $result.Length | Should -Be 32
            $result.Password.Length | Should -Be 32
            $result.Length | Should -Be $result.Password.Length
        }

        It 'Reports character counts totaling the password length' {
            $result = New-PGenRandomPassword `
                -Length 32 `
                -PassThruObject

            $totalCharacterCount = (
                $result.UppercaseCount +
                $result.LowercaseCount +
                $result.NumberCount +
                $result.SpecialCount
            )

            $totalCharacterCount | Should -Be $result.Length
        }

        It 'Reports presence flags consistent with actual counts' {
            $result = New-PGenRandomPassword `
                -Length 32 `
                -PassThruObject

            $result.ContainsUppercase |
            Should -Be ($result.UppercaseCount -gt 0)

            $result.ContainsLowercase |
            Should -Be ($result.LowercaseCount -gt 0)

            $result.ContainsNumbers |
            Should -Be ($result.NumberCount -gt 0)

            $result.ContainsSpecial |
            Should -Be ($result.SpecialCount -gt 0)
        }

        It 'Reports requested minimum requirements' {
            $result = New-PGenRandomPassword `
                -Length 24 `
                -MinimumNumbers 3 `
                -MinimumSpecial 2 `
                -PassThruObject

            $result.MinimumNumbers | Should -Be 3
            $result.MinimumSpecial | Should -Be 2
            $result.NumberCount | Should -BeGreaterOrEqual 3
            $result.SpecialCount | Should -BeGreaterOrEqual 2
        }

        It 'Reports an effective minimum of one for enabled default sets' {
            $result = New-PGenRandomPassword -PassThruObject

            $result.MinimumNumbers | Should -Be 1
            $result.MinimumSpecial | Should -Be 1
        }

        It 'Reports zero minimums when Numbers and Special are disabled' {
            $result = New-PGenRandomPassword `
                -Uppercase:$true `
                -Lowercase:$true `
                -Numbers:$false `
                -Special:$false `
                -PassThruObject

            $result.MinimumNumbers | Should -Be 0
            $result.MinimumSpecial | Should -Be 0
            $result.NumberCount | Should -Be 0
            $result.SpecialCount | Should -Be 0
        }

        It 'Reports a positive pool-based entropy value' {
            $result = New-PGenRandomPassword -PassThruObject

            $result.PoolBasedEntropyBits |
            Should -BeGreaterThan 0
        }

        It 'Reports the correct default character-pool size' {
            $result = New-PGenRandomPassword -PassThruObject

            # 26 uppercase + 26 lowercase + 10 numbers + 8 special
            $result.CharacterPoolSize | Should -Be 70
        }

        It 'Returns CopiedToClipboard as false by default' {
            $result = New-PGenRandomPassword -PassThruObject

            $result.CopiedToClipboard | Should -BeFalse
        }
    }

    Context 'Clipboard support' {

        BeforeAll {
            # Define a temporary command when Set-Clipboard is unavailable.
            # This allows the command to be mocked on non-Windows test hosts.
            if (
                -not (
                    Get-Command `
                        -Name 'Set-Clipboard' `
                        -ErrorAction SilentlyContinue
                )
            ) {
                function Set-Clipboard {
                    param (
                        [Parameter()]
                        [string[]]$Value
                    )
                }
            }
        }

        BeforeEach {
            Mock -CommandName Set-Clipboard
        }

        It 'Calls Set-Clipboard when CopyToClipboard is specified' {
            $null = New-PGenRandomPassword -CopyToClipboard

            Should -Invoke `
                -CommandName Set-Clipboard `
                -Times 1 `
                -Exactly
        }

        It 'Passes the generated password to Set-Clipboard' {
            $result = New-PGenRandomPassword -CopyToClipboard

            Should -Invoke `
                -CommandName Set-Clipboard `
                -Times 1 `
                -Exactly `
                -ParameterFilter {
                $Value -eq $result
            }
        }

        It 'Still returns a password when CopyToClipboard is specified' {
            $result = New-PGenRandomPassword -CopyToClipboard

            $result | Should -BeOfType [string]
            $result.Length | Should -Be 16
        }

        It 'Reports clipboard status when PassThruObject is used' {
            $result = New-PGenRandomPassword `
                -CopyToClipboard `
                -PassThruObject

            $result.CopiedToClipboard | Should -BeTrue

            Should -Invoke `
                -CommandName Set-Clipboard `
                -Times 1 `
                -Exactly `
                -ParameterFilter {
                $Value -eq $result.Password
            }
        }
    }

    Context 'Parameter validation' {

        It 'Throws when all character sets are disabled' {
            {
                New-PGenRandomPassword `
                    -Uppercase:$false `
                    -Lowercase:$false `
                    -Numbers:$false `
                    -Special:$false
            } | Should -Throw
        }

        It 'Throws an expected message when all sets are disabled' {
            {
                New-PGenRandomPassword `
                    -Uppercase:$false `
                    -Lowercase:$false `
                    -Numbers:$false `
                    -Special:$false
            } | Should -Throw '*At least one character set must be enabled*'
        }

        It 'Throws when Length is smaller than the default requirements' {
            {
                New-PGenRandomPassword -Length 3
            } | Should -Throw
        }

        It 'Throws when Length is smaller than explicit minimums' {
            {
                New-PGenRandomPassword `
                    -Length 4 `
                    -MinimumNumbers 3 `
                    -MinimumSpecial 3
            } | Should -Throw
        }

        It 'Includes the required minimum length in the error' {
            {
                New-PGenRandomPassword `
                    -Length 6 `
                    -MinimumNumbers 4 `
                    -MinimumSpecial 3
            } | Should -Throw '*Length must be at least 9*'
        }

        It 'Throws when AsSecureString and PassThruObject are combined' {
            {
                New-PGenRandomPassword `
                    -AsSecureString `
                    -PassThruObject
            } | Should -Throw
        }

        It 'Returns the expected conflicting-output error message' {
            {
                New-PGenRandomPassword `
                    -AsSecureString `
                    -PassThruObject
            } | Should -Throw (
                '*AsSecureString and PassThruObject cannot be used together*'
            )
        }

        It 'Rejects Length below the validation range' {
            {
                New-PGenRandomPassword -Length 0
            } | Should -Throw
        }

        It 'Rejects Length above the validation range' {
            {
                New-PGenRandomPassword -Length 4097
            } | Should -Throw
        }

        It 'Rejects a negative MinimumNumbers value' {
            {
                New-PGenRandomPassword -MinimumNumbers -1
            } | Should -Throw
        }

        It 'Rejects a negative MinimumSpecial value' {
            {
                New-PGenRandomPassword -MinimumSpecial -1
            } | Should -Throw
        }

        It 'Rejects an empty SpecialCharacters value' {
            {
                New-PGenRandomPassword -SpecialCharacters ''
            } | Should -Throw
        }
    }

    Context 'Statistical sanity checks' {

        It 'Produces unique values across a sample of 100 passwords' {
            $passwords = @(
                1..100 |
                ForEach-Object {
                    New-PGenRandomPassword
                }
            )

            $uniquePasswords = @(
                $passwords |
                Select-Object -Unique
            )

            $uniquePasswords.Count | Should -Be 100
        }

        It 'Produces multiple different values across a smaller sample' {
            $passwords = @(
                1..25 |
                ForEach-Object {
                    New-PGenRandomPassword
                }
            )

            $uniquePasswords = @(
                $passwords |
                Select-Object -Unique
            )

            $uniquePasswords.Count | Should -BeGreaterThan 10
        }

        It 'Maintains the requested length across a sample' {
            $passwords = @(
                1..25 |
                ForEach-Object {
                    New-PGenRandomPassword -Length 24
                }
            )

            $invalidPasswords = @(
                $passwords |
                Where-Object {
                    $_.Length -ne 24
                }
            )

            $invalidPasswords.Count | Should -Be 0
        }

        It 'Maintains default character requirements across a sample' {
            $passwords = @(
                1..25 |
                ForEach-Object {
                    New-PGenRandomPassword
                }
            )

            foreach ($password in $passwords) {
                $password | Should -MatchExactly '[A-Z]'
                $password | Should -MatchExactly '[a-z]'
                $password | Should -Match '[0-9]'
                $password | Should -Match '[!@#$%^&*]'
            }
        }
    }
}