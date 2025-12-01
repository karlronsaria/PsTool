#Requires -RunAs

<#
.SYNOPSIS
Uses DISM
#>
function Set-FileAssociation {
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            $suggest = dir "$PsScriptRoot/../res/assoc/*.xml" |
                foreach { $_.Name }

            $complete =
                $suggest |
                where { $_ -like "$C*" }

            if (-not $complete) {
                $suggest
            }
            else {
                $complete
            }
        })]
        [string]
        $Profile,

        [switch]
        $WhatIf
    )

    $path = "$PsScriptRoot/../res/assoc"

    if (-not $Profile) {
        return Join-Path $path "*.xml" |
            Get-ChildItem |
            foreach {
                [pscustomobject]@{
                    AvailableProfile = $_
                }
            }
    }

    $path = Join-Path $path $Profile |
        Resolve-Path

    $cmd = "dism /online /import-defaultappassociations:$path"

    if ($WhatIf) {
        $cmd
    }
    else {
        Invoke-Expression $cmd
    }
}

New-Alias `
    -Name assoc `
    -Value Set-FileAssociation `
    -Scope Global `
    -Option ReadOnly `
    -Force

