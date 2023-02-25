function Start-Edit {
    [Alias('Edit')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    $editCommand = (cat "$PsScriptRoot\..\res\setting.json" `
        | ConvertFrom-Json).EditCommand

    $path = switch ($InputObject) {
        { $_ -is [String] } {
            $InputObject
        }

        { $_ -is [Microsoft.PowerShell.Commands.MatchInfo] } {
            $InputObject.Path
        }

        { $_ -is [System.IO.FileSystemInfo] } {
            $InputObject.FullName
        }

        default { "" }
    }

    Invoke-Expression "$editCommand $path"
}

function Start-Open {
    [Alias('Open')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Switch]
        $PassThru
    )

    Process {
        $path = switch ($InputObject) {
            { $_ -is [String] } {
                $InputObject
            }

            { $_ -is [Microsoft.PowerShell.Commands.MatchInfo] } {
                $InputObject.Path
            }

            { $_ -is [System.IO.FileSystemInfo] } {
                $InputObject.FullName
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
            }

            default { [String] $InputObject }
        }

        if ($PassThru) {
            Write-Output $path
        }

        Start-Process -FilePath $path
    }
}

function What-Object {
    [Alias('What')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Parameter(ParameterSetName = 'Subscript')]
        [Int]
        $Index,

        [Parameter(ParameterSetName = 'Qualifier')]
        [String]
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

                    return $list[$i]
                }
            }
        }
    }
}
