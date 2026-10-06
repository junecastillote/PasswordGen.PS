#Dot-Source all functions
Get-ChildItem -Path $PSScriptRoot\source\*.ps1 -Recurse |
ForEach-Object {
    . $_.FullName
}

#region Load EFF Word List

$script:PGenWordList = @()

$wordListPath = Join-Path `
    -Path $PSScriptRoot `
    -ChildPath 'source\data\eff_large_wordlist.txt'

if (Test-Path -LiteralPath $wordListPath) {

    $script:PGenWordList = @(
        Get-Content `
            -LiteralPath $wordListPath |
        ForEach-Object {

            $line = $_.Trim()

            if ([string]::IsNullOrWhiteSpace($line)) {
                return
            }

            # EFF format:
            # 11111 aardvark

            $parts = $line -split '\s+', 2

            if ($parts.Count -eq 2) {
                $parts[1]
            }
        }
    )
}

#endregion

if ($script:PGenWordList.Count -eq 0) {

    throw (
        "Failed to load EFF word list from " +
        "'$wordListPath'."
    )
}