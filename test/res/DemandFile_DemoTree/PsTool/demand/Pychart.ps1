#Requires -Module PSFolderSize

<#
.DESCRIPTION
Tags: itn python pie chart

.PARAMETER NoReplaceUnderscore
Flag: Do not replace the first underscore in any label's name.

Python's matplotlib.pyplot will exclude any labels from the legend that start with an underscore '_'. `Show-Pychart` evades this behavior by replacing the first underscore with a different character (a hyphen '-'). Use this flag to turn off this behavior.

.EXAMPLE
C:\PS> Get-FolderSize | Show-Pychart -Title (Get-Location).Path -Unit "MB" -LabelProperty "FolderName" -ValueProperty "Size(MB)"

Description

-----------

This command creates a piechart of folder sizes in the working directory using the PSFolderSize module.
#>
function __Demo__Swoh-Ptrahcy {
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
        $PassThru,

        [Switch]
        $WhatIf
    )

    Begin {
        $cmd = "python"
        $script = "$PsScriptRoot\..\python\piechart.py"
        $table = @()
        $other = @()
        $total = 0
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

            if ($null -eq $value -or $value -eq 0) {
                $other += @($label)
            }

            $table += @(
                [PsCustomObject]@{
                    Label = $label
                    Value = $value
                }
            )

            $total += $value
        }

        if ($PassThru) {
            Write-Output $InputObject
        }
    }

    End {
        $setting = gc "$PsScriptRoot\..\res\pychart.setting.json" `
            | ConvertFrom-Json

        $main = $table `
            | sort `
                -Property Value `
                -Descending `
            | select `
                -First $setting.MaxLabels `
            | where {
                $_.Value / $total -gt $setting.Delta
            }

        $otherSum = ($table + @($other `
            | foreach {
                [PsCustomObject]@{
                    Label = $_
                    Value = 0
                }
            }) `
            | where {
                $_.Label -notin $main.Label
            } `
            | measure -Property Value -Sum `
        ).Sum

        $list = ((@($main) + @([PsCustomObject]@{
            Label = """$($setting.MiscellaneousLabel)"""
            Value = $otherSum
        })) | foreach {
            """$($_.Label)"""
            $_.Value
        }) -join ' '

        $argsList = "$Title $Unit $list"

        if ($WhatIf) {
            Write-Output "$cmd `"$script`" $argsList"
        } else {
            Start-Process `
                -FilePath "$cmd" `
                -ArgumentList "$script $argsList" `
                -NoNewWindow
        }
    }
}

<#
.DESCRIPTION
Tags: eme folder size pie chart PsFolderSize
#>
function __Demo__Swoh-Ftrahcezisredlo {
    Param(
        $Directory,

        [ValidateSet('GB', 'MB', 'KB', 'Bytes')]
        [String]
        $Unit,

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
        $title = (Get-Item $Directory -Force).FullName
    }
    else {
        $folders = Get-FolderSize
        $title = (Get-Location).Path
    }

    if (-not $Unit) {
        $Unit = if (($folders | measure -Property "SizeGB" -Maximum).Maximum -lt 1) {
            'MB'
        }
        else {
            'GB'
        }
    }

    $folders | Show-Pychart `
        -Title $title `
        -Unit $Unit `
        -LabelProperty { (Get-Item $_.FullPath -Force).Name } `
        -ValueProperty "Size$Unit" `
        -NoReplaceUnderscore:$NoReplaceUnderscore `
        -PassThru:$PassThru `
        -WhatIf:$WhatIf
}

