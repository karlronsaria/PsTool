#Requires -Module PSFolderSize

<#
    .PARAMETER NoReplaceUnderscore
        Flag: Do not replace the first underscore in any label's name.

        Python's matplotlib.pyplot will exclude any labels from the legend that start with an underscore '_'. `Show-Pychart` evades this behavior by replacing the first underscore with a different character (a hyphen '-'). Use this flag to turn off this behavior.
    .PARAMETER IncludeNull
        Flag: If a value is null, include its label in the chart with a value of zero, instead of discarding it.
    .EXAMPLE
        C:\PS> Get-FolderSize | Show-Pychart -Title (Get-Location).Path -Unit "MB" -LabelProperty "FolderName" -ValueProperty "Size(MB)"

        Description

        -----------

        This command creates a piechart of folder sizes in the working directory using the PSFolderSize module.
#>
function Show-Pychart {
    Param(
        [String]
        $Title = "",

        [String]
        $Unit = "",

        $LabelProperty,

        $ValueProperty,

        [Parameter(ValueFromPipeline = $true)]
        [PsObject[]]
        $InputObject,

        [Switch]
        $NoReplaceUnderscore,

        [Switch]
        $IncludeNull,

        [Switch]
        $PassThru,

        [Switch]
        $WhatIf
    )

    Begin {
        $cmd = "python"
        $script = "$PsScriptRoot\..\python\piechart.py"
        $list = $Title, $Unit
    }

    Process {
        foreach ($subitem in $InputObject) {
            $label = switch ($LabelProperty) {
                { $_ -is [ScriptBlock] } {
                    $subitem | foreach $LabelProperty
                }

                default {
                    $subitem."$LabelProperty"
                }
            }

            $value = switch ($ValueProperty) {
                { $_ -is [ScriptBlock] } {
                    $subitem | foreach $ValueProperty
                }

                default {
                    $subitem."$ValueProperty"
                }
            }

            if (-not $NoReplaceUnderscore) {
                $label = $label -Replace "^_", "-"
            }

            $label = """$label"""

            if ($null -eq $value) {
                if ($IncludeNull) {
                    $list += $label
                    $list += 0
                }

                continue
            }

            $list += $label
            $list += $value
        }

        if ($PassThru) {
            Write-Output $InputObject
        }
    }

    End {
        if ($WhatIf) {
            Write-Output "$cmd `"$script`" $list"
        } else {
            Start-Process `
                -FilePath "$cmd" `
                -ArgumentList "$script $list" `
                -NoNewWindow
        }
    }
}

function Show-FolderSizeChart {
    Param(
        $Directory,

        [ValidateSet('GB', 'KB', 'MB', 'Bytes')]
        [String]
        $Unit = 'GB',

        [Switch]
        $NoReplaceUnderscore,

        [Switch]
        $IncludeNull,

        [Switch]
        $PassThru,

        [Switch]
        $WhatIf
    )

    if ($Directory) {
        $folders = Get-FolderSize -BasePath $Directory
        $title = (Get-Item $Directory).FullName
    }
    else {
        $folders = Get-FolderSize
        $title = (Get-Location).Path
    }

    $folders | Show-Pychart `
        -Title $title `
        -Unit $Unit `
        -LabelProperty { (get-item $_.FullPath).Name } `
        -ValueProperty "Size$Unit" `
        -NoReplaceUnderscore:$NoReplaceUnderscore `
        -IncludeNull:$IncludeNull `
        -PassThru:$PassThru `
        -WhatIf:$WhatIf
}

