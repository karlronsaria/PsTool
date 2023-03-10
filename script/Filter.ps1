function Start-Edit {
    [Alias('Edit')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Switch]
        $WhatIf
    )

    $setting = cat "$PsScriptRoot\..\res\setting.json" `
        | ConvertFrom-Json

    $editCommand = $setting.EditCommand
    $useVimOpen = $setting.UseVimOpenToLine

    $path = switch ($InputObject) {
        { $_ -is [String] } {
            $InputObject
            break
        }

        { $_ -is [Microsoft.PowerShell.Commands.MatchInfo] } {
            if ($useVimOpen) {
                "`"$($InputObject.Path)`" +$($InputObject.LineNumber)"
            } else {
                $InputObject.Path
            }

            break
        }

        { $_ -is [System.IO.FileSystemInfo] } {
            $InputObject.FullName
            break
        }

        default {
            ""
            break
        }
    }

    $cmd = "$editCommand $path"

    if ($WhatIf) {
        return $cmd
    }

    Invoke-Expression $cmd
}

function Start-Open {
    [Alias('Open')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Switch]
        $PassThru,

        [Switch]
        $WhatIf
    )

    Process {
        $path = switch ($InputObject) {
            { $_ -is [String] } {
                $InputObject
                break
            }

            { $_ -is [Microsoft.PowerShell.Commands.MatchInfo] } {
                $InputObject.Path
                break
            }

            { $_ -is [System.IO.FileSystemInfo] } {
                $InputObject.FullName
                break
            }

            # interact with PsMarkdown#Get-PsMarkdownLink
            # link
            # - url: https://github.com/karlronsaria/PsMarkdown.git
            # - retrieved: 2023_02_24
            { $_ -is [PsCustomObject] } {
                $properties = $InputObject.PsObject.Properties

                if ('LinkPath' -in $properties.Name) {
                    $InputObject.LinkPath
                } else {
                    [String] $InputObject
                }
                break
            }

            default {
                [String] $InputObject
                break
            }
        }

        if ($PassThru) {
            Write-Output $path
        }

        $cmd = "Start-Process -FilePath `"$path`""

        if ($WhatIf) {
            Write-Output $cmd
        }
        else {
            Invoke-Expression $cmd
        }
    }
}

function What-Object {
    [Alias('What')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Parameter(ParameterSetName = 'Subscript')]
        [Int[]]
        $Index,

        [Parameter(ParameterSetName = 'Qualifier')]
        [String[]]
        $Property,

        [Parameter(ParameterSetName = 'GetFirst')]
        [Switch]
        $First,

        [Parameter(
            ParameterSetName = 'Inference',
            Position = 0
        )]
        $Argument
    )

    Begin {
        $list = @()
    }

    Process {
        switch ($PsCmdlet.ParameterSetName) {
            'Qualifier' {
                if (@($Property).Count -gt 1) {
                    foreach ($item in $Property) {
                        Write-Output $InputObject.$item
                    }

                    return
                }

                return $InputObject.$Property
            }

            default {
                $list += @($InputObject)
            }
        }
    }

    End {
        if ($list.Count -gt 0) {
            switch ($PsCmdlet.ParameterSetName) {
                'Inference' {
                    switch ($Argument) {
                        { @($Argument).Count -gt 1 } {
                            foreach ($item in $Argument) {
                                Write-Output $list | What-Object `
                                    -Argument $item
                            }

                            return
                        }

                        { $d = $null; [Int]::TryParse($_, [ref]$d) } {
                            return $list | What-Object `
                                -Index $Argument
                        }

                        default {
                            return $list | What-Object `
                                -Property $Argument
                        }
                    }
                }

                default {
                    $i = switch ($PsCmdlet.ParameterSetName) {
                        'Subscript' { $Index }
                        'GetFirst' { 0 }
                    }

                    if (@($i).Count -gt 1) {
                        foreach ($item in $i) {
                            Write-Output $list[$item]
                        }

                        return
                    }

                    return $list[$i]
                }
            }
        }
    }
}
