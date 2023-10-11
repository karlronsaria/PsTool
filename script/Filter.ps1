function Start-Edit {
    [Alias('Edit')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Switch]
        $WhatIf
    )

    Begin {
        $setting = cat "$PsScriptRoot\..\res\filter.setting.json" `
            | ConvertFrom-Json

        $editCommand = $setting.EditCommand
        $useVimOpen = $setting.UseVimOpenToLine
        $map = [Ordered]@{}
    }

    Process {
        $path = ""
        $command = ""

        switch ($InputObject) {
            { $_ -is [String] } {
                $path = $InputObject
                break
            }

            { $_ -is [Microsoft.PowerShell.Commands.MatchInfo] } {
                $path = $InputObject.Path

                if ($useVimOpen) {
                    $command = "`"$($path)`" +$($InputObject.LineNumber)"
                }

                break
            }

            { $_ -is [System.IO.FileSystemInfo] } {
                $path = $InputObject.FullName
                break
            }

            default {
                $path = ""
                break
            }
        }

        if ([String]::IsNullOrEmpty($command)) {
            $command = $path
        }

        $map[$path] = $command
    }

    End {
        foreach ($key in $map.Keys) {
            $cmd = "$editCommand $($map[$key])"

            if ($WhatIf) {
                return $cmd
            }

            Invoke-Expression $cmd
        }
    }
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

function Qualify-Object {
    [Alias('What')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Parameter(ParameterSetName = 'Subscript')]
        [Int[]]
        $Index,

        [ArgumentCompleter({
            # link
            # - url: https://stackoverflow.com/questions/65892518/tab-complete-a-parameter-value-based-on-another-parameters-already-specified-va
            # - retrieved: 2023_10_10
            Param(
                $cmdName,
                $paramName,
                $wordToComplete,
                $cmdAst,
                $preBoundParameters
            )

            # Find out if we have pipeline input.
            $pipelineElements = $cmdAst.Parent.PipelineElements
            $thisPipelineElementAsString = $cmdAst.Extent.Text

            $thisPipelinePosition = [Array]::IndexOf(
                $pipelineElements.Extent.Text,
                $thisPipelineElementAsString
            )

            $hasPipelineInput = $thisPipelinePosition -ne 0
            $possibleArguments = @()

            if ($hasPipelineInput) {
                # If we are in a pipeline, find out if the previous pipeline
                # element is a variable or a command.
                $previousPipelineElement =
                    $pipelineElements[$thisPipelinePosition - 1]

                $pipelineInputVariable =
                    $previousPipelineElement.Expression.VariablePath.UserPath

                if (-not [string]::IsNullOrEmpty($pipelineInputVariable)) {
                    # If previous pipeline element is a variable, get the
                    # object. Note that it can be a non-existent variable.
                    # In such case we simply get nothing.
                    $detectedInputObject = Get-Variable |
                        Where-Object {$_.Name -eq $pipelineInputVariable} |
                        ForEach-Object Value
                } else {
                    $pipelineInputCommand =
                        $previousPipelineElement.CommandElements[0].Value

                    if (-not [string]::IsNullOrEmpty($pipelineInputCommand)) {
                        # If previous pipeline element is a command, check
                        # if it exists as a command.
                        $possibleArguments += Get-Command -CommandType All |
                            where Name -Match "^$pipelineInputCommand$" |
                            # Collect properties for each documented output
                            # type.
                            foreach { $_.OutputType.Type } |
                            foreach GetProperties |
                            # Group properties by Name to get unique ones,
                            # and sort them by the most frequent Name first.
                            # The sorting is a perk. A command can have
                            # multiple output types. If so, we might now have
                            # multiple properties with identical Name.
                            group Name -NoElement |
                            sort Count -Descending |
                            foreach Name
                    }
                }
            }
            elseif ($preBoundParameters.ContainsKey("InputObject")) {
                # If not in pipeline, but object has been given, get the
                # object.
                $detectedInputObject = $preBoundParameters["InputObject"]
            }

            if ($null -ne $detectedInputObject) {
                # The input object might be an array of objects, if so,
                # select the first one. We (at least I) are not interested in
                # array properties, but the object element's properties.
                $sampleInputObject = if ($detectedInputObject -is [Array]) {
                    $detectedInputObject[0]
                } else {
                    $detectedInputObject
                }

                # Collect property names.
                $possibleArguments =
                    @($sampleInputObject.PsObject.Properties.Name) +
                    @($possibleArguments)
            }

            $suggestions = if ($wordToComplete) {
                $possibleArguments | where { $_ -like "$wordToComplete*" }
            }
            else {
                $possibleArguments
            }

            return $(if ($suggestions) {
                $suggestions
            }
            else {
                $possibleArguments
            })
        })]
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
                                Write-Output $list | Qualify-Object `
                                    -Argument $item
                            }

                            return
                        }

                        { $d = $null; [Int]::TryParse($_, [ref]$d) } {
                            return $list | Qualify-Object `
                                -Index $Argument
                        }

                        default {
                            return $list | Qualify-Object `
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
