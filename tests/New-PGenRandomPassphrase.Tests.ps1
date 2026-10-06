BeforeAll {

    $functionPath = Join-Path `
        $PSScriptRoot `
        '../source/public/New-PGenRandomPassphrase.ps1'

    . (Resolve-Path $functionPath)

    if (-not $script:PGenWordList) {

        $script:PGenWordList = @(
            'forest'
            'lantern'
            'silver'
            'ocean'
            'river'
            'anchor'
            'window'
            'coffee'
            'echo'
            'valley'
        )
    }
}

Describe 'New-PGenRandomPassphrase' {

    Context 'Default generation' {

        It 'Returns a string' {

            $result = New-PGenRandomPassphrase

            $result | Should -BeOfType [string]
        }

        It 'Generates four words by default' {

            $result = New-PGenRandomPassphrase

            ($result -split '-') |
            Should -HaveCount 4
        }
    }

    Context 'WordCount' {

        It 'Generates the requested number of words' {

            $result = New-PGenRandomPassphrase `
                -WordCount 6

            ($result -split '-') |
            Should -HaveCount 6
        }
    }

    Context 'Separator' {

        It 'Uses the requested separator' {

            $result = New-PGenRandomPassphrase `
                -Separator '_'

            $result |
            Should -Match '_'

            $result |
            Should -Not -Match '-'
        }
    }

    Context 'CapitalizeWords' {

        It 'Capitalizes all words' {

            $result = New-PGenRandomPassphrase `
                -CapitalizeWords

            foreach ($word in ($result -split '-')) {

                $word.Substring(0, 1) |
                Should -MatchExactly '[A-Z]'
            }
        }
    }

    Context 'AddNumber' {

        It 'Adds a number component' {

            $result = New-PGenRandomPassphrase `
                -AddNumber

            $result |
            Should -Match '[0-9]'
        }

        It 'Honors NumberLength' {

            $result = New-PGenRandomPassphrase `
                -AddNumber `
                -NumberLength 4 `
                -PassThruObject

            $result.NumberValue |
            Should -Match '^[0-9]{4}$'
        }
    }

    Context 'SecureString output' {

        It 'Returns SecureString when requested' {

            $result = New-PGenRandomPassphrase `
                -AsSecureString

            $result |
            Should -BeOfType `
                [System.Security.SecureString]
        }
    }

    Context 'PassThruObject output' {

        It 'Returns PSCustomObject' {

            $result = New-PGenRandomPassphrase `
                -PassThruObject

            $result |
            Should -BeOfType `
                [pscustomobject]
        }

        It 'Reports correct WordCount' {

            $result = New-PGenRandomPassphrase `
                -WordCount 6 `
                -PassThruObject

            $result.WordCount |
            Should -Be 6
        }

        It 'Reports word list source' {

            $result = New-PGenRandomPassphrase `
                -PassThruObject

            $result.WordListSource |
            Should -Be 'EFF Large Word List'
        }

        It 'Reports positive entropy value' {

            $result = New-PGenRandomPassphrase `
                -PassThruObject

            $result.EstimatedEntropyBits |
            Should -BeGreaterThan 0
        }
    }

    Context 'Clipboard support' {

        BeforeEach {

            Mock Set-Clipboard

            Mock Get-Command {
                @{
                    Name = 'Set-Clipboard'
                }
            }
        }

        It 'Calls Set-Clipboard' {

            $null = New-PGenRandomPassphrase `
                -CopyToClipboard

            Should -Invoke `
                -CommandName Set-Clipboard `
                -Times 1
        }
    }

    Context 'Validation' {

        It 'Throws when AsSecureString and PassThruObject are combined' {

            {
                New-PGenRandomPassphrase `
                    -AsSecureString `
                    -PassThruObject
            } | Should -Throw
        }

        It 'Throws when the word list is missing' {

            $oldList = $script:PGenWordList

            try {

                $script:PGenWordList = @()

                {
                    New-PGenRandomPassphrase
                } | Should -Throw
            }
            finally {

                $script:PGenWordList = $oldList
            }
        }
    }

    Context 'Generation sanity checks' {

        It 'Produces unique values across a sample' {

            $results = @(
                1..50 |
                ForEach-Object {
                    New-PGenRandomPassphrase
                }
            )

            ($results | Select-Object -Unique).Count |
            Should -Be 50
        }
    }
}