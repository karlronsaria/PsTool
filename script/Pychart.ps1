<#
    .PARAMETER NoReplaceUnderscore
        Flag: Do not replace the first underscore in any label's name.

        Python's matplotlib.pyplot will exclude any labels from the legend that start with an underscore '_'. `Show-Pychart` evades this behavior by replacing the first underscore with a different character (a hyphen '-'). Use this flag to turn off this behavior.
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

        [String]
        $LabelProperty,

        [String]
        $ValueProperty,

        [Parameter(ValueFromPipeline = $true)]
        [PsObject[]]
        $InputObject,

        [Switch]
        $NoReplaceUnderscore,

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
        foreach ($subobject in $InputObject) {
            $label = $_."$LabelProperty"

            if (-not $NoReplaceUnderscore) {
                $label = $label -Replace "^_", "-"
            }

            $list += $label
            $list += $_."$ValueProperty"
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
