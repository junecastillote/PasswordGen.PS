[CmdletBinding(SupportsShouldProcess)]
param ()

$moduleFilename = Join-Path `
    -Path $PSScriptRoot `
    -ChildPath 'PasswordGen.PS.psd1'

$moduleManifest = Test-ModuleManifest `
    -Path (
    (Get-Item -Path $moduleFilename -ErrorAction Stop).FullName
)

$installedModules = Get-Module `
    -Name $moduleManifest.Name `
    -ListAvailable

if (-not $installedModules) {

    Write-Output (
        "[{0}] module not found. Nothing to uninstall." -f
        $moduleManifest.Name
    )

    return
}

foreach (
    $moduleInfo in (
        $installedModules |
        Sort-Object Version -Descending
    )
) {

    try {

        Remove-Module `
            -Name $moduleInfo.Name `
            -ErrorAction SilentlyContinue

        $moduleVersionPath = $moduleInfo.ModuleBase

        if (
            -not (
                Test-Path -LiteralPath $moduleVersionPath
            )
        ) {

            Write-Warning (
                "Path not found: '{0}'" -f
                $moduleVersionPath
            )

            continue
        }

        if (
            $PSCmdlet.ShouldProcess(
                $moduleVersionPath,
                "Remove module version $($moduleInfo.Version)"
            )
        ) {

            Remove-Item `
                -LiteralPath $moduleVersionPath `
                -Recurse `
                -Force `
                -ErrorAction Stop

            Write-Output (
                "Removed [{0} version {1}] from [{2}]" -f
                $moduleInfo.Name,
                $moduleInfo.Version,
                $moduleVersionPath
            )
        }

        #
        # Remove module parent folder if empty.
        #
        # Example:
        # Modules\PasswordGen.PS
        #

        $moduleRootFolder = Split-Path `
            -Path $moduleVersionPath `
            -Parent

        if (
            (Test-Path -LiteralPath $moduleRootFolder) -and
            -not (
                Get-ChildItem `
                    -LiteralPath $moduleRootFolder `
                    -Force
            )
        ) {

            if (
                $PSCmdlet.ShouldProcess(
                    $moduleRootFolder,
                    'Remove empty module root folder'
                )
            ) {

                Remove-Item `
                    -LiteralPath $moduleRootFolder `
                    -Force `
                    -ErrorAction Stop

                Write-Verbose (
                    "Removed empty folder '{0}'" -f
                    $moduleRootFolder
                )
            }
        }
    }
    catch {

        Write-Warning (
            "Failed to uninstall {0} version {1}: {2}" -f
            $moduleInfo.Name,
            $moduleInfo.Version,
            $_.Exception.Message
        )
    }
}