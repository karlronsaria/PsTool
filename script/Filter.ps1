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

function Start-Explore {
    [Alias('Explore')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Switch]
        $PassThru,

        [Switch]
        $WhatIf
    )

    Begin {
        $list = @()
    }

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

        if (Test-Path -Path $path -PathType Leaf) {
            $path = (Get-Item $path).Directory
        }

        $list += @($path)
    }

    End {
        foreach ($path in $list | sort -Unique) {
            if ($PassThru) {
                Write-Output $path
            }

            Invoke-Item -Path $path -WhatIf:$WhatIf
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

function Get-PipelinePropertySuggestion {
    # link
    # - url: https://stackoverflow.com/questions/65892518/tab-complete-a-parameter-value-based-on-another-parameters-already-specified-va
    # - retrieved: 2023_10_10
    Param(
        $WordToComplete,
        $CommandAst,
        $PreboundParameters
    )

    # Find out if we have pipeline input.
    $pipelineElements = $CommandAst.Parent.PipelineElements
    $thisPipelineElementAsString = $CommandAst.Extent.Text

    $thisPipelinePosition = [Array]::IndexOf(
        $pipelineElements.Extent.Text,
        $thisPipelineElementAsString
    )

    $hasPipelineInput = $thisPipelinePosition -ne 0
    $possibleArgs = @()

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
            $detectedInputObject = Get-Variable `
                -Name $pipelineInputVariable |
                foreach Value
        }
        elseif ($previousPipelineElement.CommandElements.Count -gt 0) {
            $pipelineInputCommand =
                $previousPipelineElement.CommandElements[0].Value

            if (-not [string]::IsNullOrEmpty($pipelineInputCommand)) {
                # If previous pipeline element is a command, check
                # if it exists as a command.
                $possibleArgs += Get-Command `
                    -Name $pipelineInputCommand |
                    foreach { $_.OutputType.Type } |
                    foreach GetProperties |
                    group Name -NoElement |
                    foreach Name
            }
        }
        else {
            $obj = $previousPipelineElement.Expression

            $possibleArgs += @(switch ($obj.StaticType) {
                { $_ -eq [PsCustomObject] } {
                    $obj.Child.KeyValuePairs.Item1.Value
                }

                { $_ -eq [Hashtable] } {
                    $obj.KeyValuePairs.Item1.Value
                }

                { $_ -eq [Object[]] } {
                    foreach ($element in $obj.
                        Subexpression.
                        Statements.
                        PipelineElements.
                        Expression.
                        Elements
                    ) {
                        switch ($element.StaticType) {
                            { $_ -eq [PsCustomObject] } {
                                $element.Child.KeyValuePairs.Item1.Value
                            }

                            { $_ -eq [Hashtable] } {
                                $element.KeyValuePairs.Item1.Value
                            }
                        }
                    }
                }
            })
        }
    }
    elseif ($PreboundParameters.ContainsKey("InputObject")) {
        # If not in pipeline, but object has been given, get the object.
        $detectedInputObject = $PreboundParameters["InputObject"]
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
        $possibleArgs =
            @($sampleInputObject.PsObject.Properties.Name) +
            @($possibleArgs)
    }

    $suggestions = if ($WordToComplete) {
        $possibleArgs | where { $_ -like "$WordToComplete*" }
    }
    else {
        $possibleArgs
    }

    $suggestions = if ($suggestions) {
        $suggestions
    }
    else {
        $possibleArgs
    }

    return $suggestions | foreach {
        if ($_ -match "\s") {
            "`"$_`""
        }
        else {
            $_
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
            Param(
                $CommandName,
                $ParameterName,
                $WordToComplete,
                $CommandAst,
                $PreboundParameters
            )

            return Get-PipelinePropertySuggestion @PsBoundParameters
        })]
        [Parameter(ParameterSetName = 'Qualifier')]
        [String[]]
        $Property,

        [Parameter(ParameterSetName = 'GetFirst')]
        [Switch]
        $First,

        [Switch]
        $Numbered,

        [ArgumentCompleter({
            Param(
                $CommandName,
                $ParameterName,
                $WordToComplete,
                $CommandAst,
                $PreboundParameters
            )

            return Get-PipelinePropertySuggestion @PsBoundParameters
        })]
        [Parameter(
            ParameterSetName = 'Inference',
            Position = 0
        )]
        $Argument
    )

    Begin {
        $list = @()

        function Get-Subelement {
            Param(
                $InputObject,

                [String]
                $ElementName
            )

            switch ($InputObject) {
                { $_ -is [Hashtable] } {
                    $InputObject[$ElementName]
                }

                default {
                    $InputObject.$ElementName
                }
            }
        }
    }

    Process {
        switch ($PsCmdlet.ParameterSetName) {
            'Qualifier' {
                if (@($Property).Count -gt 1) {
                    foreach ($item in $Property) {
                        Get-Subelement `
                            -InputObject $InputObject `
                            -ElementName $item
                    }

                    return
                }

                Get-Subelement `
                    -InputObject $InputObject `
                    -ElementName $Property
            }

            default {
                $list += @($InputObject)
            }
        }
    }

    End {
        if ($list.Count -eq 0) {
            return
        }

        $list = switch ($PsCmdlet.ParameterSetName) {
            'Inference' {
                switch ($Argument) {
                    { @($Argument).Count -gt 1 } {
                        foreach ($item in $Argument) {
                            $list | Qualify-Object `
                                -Argument $item
                        }

                        break
                    }

                    { $d = $null; [Int]::TryParse($_, [ref]$d) } {
                        $list | Qualify-Object `
                            -Index $Argument

                        break
                    }

                    default {
                        $list | Qualify-Object `
                            -Property $Argument

                        break
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
                        $list[$item]
                    }

                    return
                }

                $list[$i]
            }
        }

        return $(if ($Numbered) {
            $list | foreach -Begin {
                $count = 0
            } -Process {
                [PsCustomObject]@{
                    Id = ++$count
                    Object = $_
                }
            }
        }
        else {
            $list
        })
    }
}

<#
.SYNOPSIS
A string replacer that preserves casing
#>
function Get-StringReplace {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $InputObject,

        [String]
        $Pattern,

        [String]
        $Replace
    )

    Process {
        $captures = [Regex]::Matches($InputObject, $Pattern)
        $index = 0
        $objects = @()

        $objects += @(foreach ($capture in $captures) {
            $prefix = if ($capture.Index -ne 0) {
                $InputObject[$index .. ($capture.Index - 1)] -join ""
            }

            $index = $capture.Index + $capture.Length

            [PsCustomObject]@{
                Prefix = $prefix
                Capture = $capture
            }
        })

        if ($index -lt $InputObject.Length) {
            $objects += @([PsCustomObject]@{
                Prefix = $InputObject[$index .. ($InputObject.Length - 1)]
                Capture = $null
            })
        }

        ($objects | foreach {
            $caseSlice = ""
            $remainder = ""

            if ($null -ne $_.Capture) {
                $value = $_.Capture.Value
                $min = [Math]::Min($value.Length, $Replace.Length)

                $caseSlice = foreach ($i in (0 .. $min)) {
                    $c = $value[$i]

                    if ($c -cmatch "[A-Z]") {
                        [Char]::ToUpper($Replace[$i])
                    }
                    elseif ($c -cmatch "[a-z]") {
                        [Char]::ToLower($Replace[$i])
                    }
                    else {
                        $Replace[$i]
                    }
                }

                $remainder = if ($Replace.Length -gt $min) {
                    $Replace[($min + 1) .. ($Replace.Length - 1)]
                }
            }

            "$(
                $_.Prefix -join ''
            )$(
                $caseSlice -join ''
            )$(
                $remainder -join ''
            )"
        }) -join ""
    }
}

function ConvertTo-List {
    [Alias('List')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [PsCustomObject[]]
        $InputObject
    )

    Process {
        return $InputObject | foreach {
            $_.PsObject.Properties | foreach {
                [PsCustomObject]@{
                    Name = $_.Name
                    Value = $_.Value
                }
            }
        }
    }
}
