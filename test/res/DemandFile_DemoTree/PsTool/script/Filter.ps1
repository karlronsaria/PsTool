function __Demo__Strat-Etid {
    [Alias('Edit')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Switch]
        $Sudo,

        [ArgumentCompleter({
            return ConvertTo-Suggestion `
                -WordToComplete $args[2] `
                -List $(
                    (gc "$PsScriptRoot\..\res\filter.setting.json" |
                    ConvertFrom-Json).
                    Editor.
                    PsObject.
                    Properties.
                    Name |
                    where {
                        $_ -ne 'Other'
                    }
                )
        })]
        [String]
        $Editor,

        [Int]
        $LineNumber = 0,

        [Switch]
        $WhatIf
    )

    Begin {
        $setting = gc "$PsScriptRoot\..\res\filter.setting.json" |
        ConvertFrom-Json

        $editors =
            $setting.
            Editor

        $editorNames =
            $editors.
            PsObject.
            Properties.
            Name

        # link
        # - url: <https://stackoverflow.com/questions/57788150/can-i-detect-in-powershell-that-i-am-running-in-vs-codes-integrated-terminal>
        # - retrieved: 2023-12-07
        $name = if ($Editor) {
            $Editor
        }
        elseif ($env:TERM_PROGRAM -eq 'vscode') {
            'VsCode'
        }
        else {
            $setting.DefaultEditor
        }

        $editorInfo = if ($name -in $editorNames) {
            $editors.$name
        }
        else {
            $myEditor =
                $editors.
                Other

            $myEditor.
                PsObject.
                Properties |
                foreach {
                    $_.Value = $_.Value.Replace('<app>', $name)
                }

            $myEditor
        }

        $editCommand =
            $editorInfo.
            "$(if ($Sudo) { "Elevated" })Command"

        $line = if ($LineNumber -eq 0) {
            ""
        }
        else {
            "$LineNumber"
        }

        # Using a map instead of a list ensures that each possible unique
        # path is opened exactly once.
        $map = [Ordered]@{}
    }

    Process {
        $info = switch ($InputObject) {
            { $_ -is [String] } {
                [PsCustomObject]@{
                    Path = $InputObject
                    Line = $line
                }

                break
            }

            { $_ -is [Microsoft.PowerShell.Commands.MatchInfo] } {
                [PsCustomObject]@{
                    Path = $InputObject.Path
                    Line = if ([String]::IsNullOrEmpty($line)) {
                        "$($InputObject.LineNumber)"
                    }
                    else {
                        $line
                    }
                }

                break
            }

            { $_ -is [System.IO.FileSystemInfo] } {
                [PsCustomObject]@{
                    Path = $InputObject.FullName
                    Line = $line
                }

                break
            }

            default {
                [PsCustomObject]@{
                    Path = $InputObject | Out-String
                    Line = $line
                }

                break
            }
        }

        if ($info.Line) {
            $info.Line = "$($editorInfo.GotoLineSequence)$($info.Line)"
        }

        $map[$info.Path] = $info
    }

    End {
        foreach ($key in $map.Keys) {
            $cmd = $editCommand.
                Replace('<path>', "$($map[$key].Path)").
                Replace('<line>', "$($map[$key].Line)")

            if ($WhatIf) {
                $cmd
                continue
            }

            Invoke-Expression $cmd
        }
    }
}

function __Demo__Strat-Eerolpx {
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
            # - retrieved: 2023-02-24
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
        foreach ($path in $list | Sort-Object -Unique) {
            if ($PassThru) {
                Write-Output $path
            }

            Invoke-Item -Path $path -WhatIf:$WhatIf
        }
    }
}

function __Demo__Strat-Onep {
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
            # - retrieved: 2023-02-24
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

function __Demo__Cottrevno-Snoitseggu {
    Param(
        $List,
        $WordToComplete
    )

    $suggestions = if ($wordToComplete) {
        $List | where {
            $_ -like "$WordToComplete*"
        }
    }
    else {
        $List
    }

    return $(if ($suggestions) {
        $suggestions
    }
    else {
        $List
    })
}

function __Demo__Gte-Pnoitseggusytreporpenilepi {
    # link
    # - url: <https://stackoverflow.com/questions/65892518/tab-complete-a-parameter-value-based-on-another-parameters-already-specified-va>
    # - retrieved: 2023-10-10
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
    elseif ($PreboundParameters.ContainsKey('InputObject')) {
        # If not in pipeline, but object has been given, get the object.
        $detectedInputObject = $PreboundParameters['InputObject']
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

function __Demo__Qyreu-Otcejb {
    [Alias('What', 'Query')]
    [CmdletBinding(DefaultParameterSetName = 'GetAny')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Parameter(ParameterSetName = 'GetAny')]
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
        $Property,

        [Parameter(ParameterSetName = 'GetFirst')]
        [Switch]
        $First,

        [Switch]
        $Numbered,

        [Alias('Flat')]
        [Switch]
        $NoHeadings,

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
        [Parameter(Position = 0)]
        $Argument,

        $Default
    )

    Begin {
        function Get-Subobject {
            Param(
                $InputObject,

                [String]
                $Name
            )

            switch ($InputObject) {
                { $_ -is [Ordered] -or $_ -is [Hashtable] } {
                    $_[$Name]
                }

                default {
                    $_.$Name
                }
            }
        }

        function Get-Subelement {
            [CmdletBinding(DefaultParameterSetName = 'ByStruct')]
            Param(
                $InputObject,

                $ElementStruct,

                [Switch]
                $NoHeadings,

                [Parameter(ParameterSetName = 'ByNextKey')]
                [String]
                $NextKey
            )

            switch ($PsCmdlet.ParameterSetName) {
                # Iterate
                'ByNextKey' {
                    foreach ($item in $InputObject) {
                        $value = Get-Subelement `
                            -InputObject ( `
                                Get-Subobject `
                                    -InputObject $item `
                                    -Name $NextKey `
                            ) `
                            -ElementStruct $ElementStruct `
                            -NoHeadings:$NoHeadings

                        if ($NoHeadings) {
                            $value
                        }
                        else {
                            [PsCustomObject]@{
                                $NextKey = $value
                            }
                        }
                    }
                }

                'ByStruct' {
                    $NoHeadings =
                        $NoHeadings -or
                        @($InputObject).Count -eq 1

                    foreach ($element in @($ElementStruct)) {
                        switch ($element) {
                            # Pre-orbit
                            { $_ -is [Ordered] -or $_ -is [Hashtable] } {
                                foreach ($key in $_.Keys) {
                                    Get-Subelement `
                                        -InputObject $InputObject `
                                        -ElementStruct $_[$key] `
                                        -NextKey $key `
                                        -NoHeadings:$NoHeadings
                                }

                                break
                            }

                            # Pre-orbit
                            { $_ -is [PsCustomObject] } {
                                foreach ($prop in $_.PsObject.Properties) {
                                    Get-Subelement `
                                        -InputObject $InputObject `
                                        -ElementStruct $prop.Value `
                                        -NextKey $prop.Name `
                                        -NoHeadings:$NoHeadings
                                }

                                break
                            }

                            # Fixed Point
                            { $_ -is [String] } {
                                foreach ($item in $InputObject) {
                                    Get-Subobject `
                                        -InputObject $item `
                                        -Name $ElementStruct
                                }

                                break
                            }
                        }
                    }
                }
            }
        }

        $list = @()
    }

    Process {
        $list += $(
            if ($Property) {
                foreach ($prop in $Property) {
                    foreach ($item in $InputObject) {
                        Get-Subelement `
                            -InputObject $item `
                            -ElementStruct $prop `
                            -NoHeadings:$NoHeadings
                    }
                }
            }
            else {
                @($InputObject)
            }
        )
    }

    End {
        if (-not $list) {
            if ($Default) {
                $Default
            }

            return
        }

        if ($Argument) {
            $Property = @()

            foreach ($a in $Argument) {
                switch ($a) {
                    { $_ -is [Int] -or "$_" -match "^\s*\d+\s*$" } {
                        $Index += @($_)
                        break
                    }

                    default {
                        $Property += @($_)
                        break
                    }
                }
            }

            $list = $list | Query-Object `
                -Property $Property
        }

        if ($Numbered) {
            $list = $list |
            foreach -Begin {
                $count = 0
            } -Process {
                [PsCustomObject]@{
                    Id = ++$count
                    Object = $_
                }
            }
        }

        if ($GetFirst) {
            return $list[0]
        }

        if ($Index) {
            $list = $Index |
            foreach {
                $list[$_]
            }
        }

        return $list
    }
}

<#
.SYNOPSIS
A string replacer that preserves casing
#>
function __Demo__Gte-Secalpergnirt {
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
                $InputObject[$index .. ($capture.Index - 1)] -join ''
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

        @($objects | foreach {
            $caseSlice = ''
            $remainder = ''

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
        }) -join ''
    }
}

function __Demo__Cottrevno-Ltsi {
    [Alias('List')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [PsCustomObject[]]
        $InputObject
    )

    Process {
        return $(
            $InputObject |
            foreach {
                $_.PsObject.Properties
            } | foreach {
                [PsCustomObject]@{
                    Name = $_.Name
                    Value = $_.Value
                }
            }
        )
    }
}

