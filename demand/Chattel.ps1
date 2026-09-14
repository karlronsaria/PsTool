# (karlr 2026-09-14): Please make private
function Write-ChattelMdTable {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $List,

        [int]
        $Level,

        [int]
        $Indent
    )
    
    Begin {
        $tempList = @()
    }
    
    Process {
        $tempList += @($List)
    }

    End {
        return @(
            $tempList |
                Write-MdTable |
                ForEach-Object { "$(' ' * ($Level * $Indent))$_" }
        )
    }
}

# (karlr 2026-09-13): Please make private
function Compare-ChattelDescriptor {
    Param(
        [Parameter(Position = 0)]
        [string]
        $A,

        [Parameter(Position = 1)]
        [string]
        $B
    )

    $A = [regex]::Match($A, "(?<=\W*)\w.+").Value
    $B = [regex]::Match($B, "(?<=\W*)\w.+").Value

    if ($A -eq $B) { return 0 }
    
    if ($A -match "^[a-zA-Z]\d+$" -and $B -match "^[a-zA-Z]\d*[a-zA-Z]") {
        return -1
    }
    
    if ($B -match "^[a-zA-Z]\d+$" -and $A -match "^[a-zA-Z]\d*[a-zA-Z]") {
        return 1
    }
    
    return $A.CompareTo($B)
}

# (karlr 2026-09-13): Please make private
function Get-ChattelItemDescriptor {
    Param(
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst
    )

    $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

    $valuesSoFar = $CommandAst.
        Parent.
        PipelineElements[-1].
        CommandElements[-1].
        NestedAst.
        Value

    if ($valuesSoFar) {
        $items = Get-ChattelItem -Descriptor $valuesSoFar
    }

    if (-not $items) {
        $items = "$PsScriptRoot/../res/chattel.setting.json" |
            Get-Item |
            Get-Content |
            ConvertFrom-Json |
            ForEach-Object { Join-Path $_.NotebookPath 'item.md' } |
            Get-Item |
            Get-Content |
            Get-MarkdownTree |
            ForEach-Object item |
            ForEach-Object _Table
    }
    
    $list = [System.Collections.Generic.List[string]]::new()

    $items.descriptor |
        Select-Object -Unique |
        Where-Object { $_ -like "*$($WordToComplete.Trim('"'))*" } |
        Where-Object { $_ -notin $valuesSoFar } |
        ForEach-Object { "`"$_`"" } |
        ForEach-Object { $list.Add($_) } |
        Out-Null

    $list.Sort({ Compare-ChattelDescriptor $args[0] $args[1] })

    $list |
        ForEach-Object { $CompletionResults.Add($_) } |
        Out-Null

    return $CompletionResults
}

function Get-ChattelItem {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param(
        [Parameter(ParameterSetName = 'ByDescriptor')]
        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )

            return Get-ChattelItemDescriptor `
                -WordToComplete $WordToComplete `
                -CommandAst $CommandAst
        })]
        [string[]]
        $Descriptor,

        [Parameter(ParameterSetName = 'ById')]
        [string[]]
        $Id
    )
    
    $setting =
        Get-Item "$PsScriptRoot/../res/chattel.setting.json" |
        Get-Content |
        ConvertFrom-Json

    $table = 
        Join-Path $setting.NotebookPath 'item.md' |
        Get-Item |
        Get-Content |
        Get-MarkdownTree |
        ForEach-Object item |
        ForEach-Object _Table
        
    $tree = $table |
        ForEach-Object -Begin {
            $row = $null
        } -Process {
            if ($_.id) {
                if ($row) { $row }

                $row = $_
                $row.descriptor = @($row.descriptor)
            }
            else {
                $row.descriptor += $_.descriptor
            }
        } -End { $row }
        
    $tree | ForEach-Object {
        $properties =
            Join-Path `
                $setting.NotebookPath `
                "item/item_-_$($_.id).md" |
            Where-Object { Test-Path $_ } |
            Get-Item |
            Get-Content |
            Get-MarkdownTree |
            Get-NextTree |
            ForEach-Object PsObject |
            ForEach-Object Properties

        foreach ($property in $properties) {
            $name = $property.Name
            
            $value = $property.Value |
                ForEach-Object _Table |
                Sort-Object -Property when |
                Select-Object -Last 1
                
            if (-not $value) {
                continue
            }
            
            $value = $value.PsObject.Properties |
                Where-Object { $_.Name.ToLower() -ne 'when' } |
                Select-Object -First 1 |
                ForEach-Object Value

            $tree | Add-Member `
                -MemberType NoteProperty `
                -Name $name `
                -Value $value
        }
    }

    return $(switch ($PsCmdlet.ParameterSetName) {
        'All' {
            $tree
        }

        'ByDescriptor' {
            $tree |
                Where-Object {
                    @($_.descriptor).Count -ge @($Descriptor).Count -and
                    @(Compare-Object @($Descriptor) @($_.descriptor) |
                        ForEach-Object SideIndicator) -notcontains "<="
                }
        }

        'ById' {
            $tree |
                Where-Object id -in $Id
        }
    })
}

function Get-ChattelStory {
    Param(
        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true
        )]
        [Alias('Id')]
        [string]
        $ItemId
    )

    Process {
        Get-Item "$PsScriptRoot/../res/chattel.setting.json" |
            Get-Content |
            ConvertFrom-Json |
            ForEach-Object { Join-Path $_.NotebookPath 'story.md' } |
            Get-Item |
            Get-Content |
            Get-MarkdownTree |
            ForEach-Object story |
            ForEach-Object _Table |
            Where-Object { $_.ItemId -eq $ItemId }
    }
}

function New-ChattelStory {
    Param(
        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true
        )]
        [Alias('Id')]
        [string]
        $ItemId,

        [string]
        $What,

        [string]
        $Start,

        [string]
        $End
    )

    Begin {
        function Get-Headings {
            Param(
                [string]
                $StoryPath
            )

            $lines = $StoryPath |
                Get-Item |
                Get-Content

            $i = 0

            while ($i -lt $lines.Count) {
                $capture = [regex]::Matches($lines[$i], "((?<heading>\S+)\s*\|)+")

                if ($capture.Success) {
                    return $capture.Groups |
                        Where-Object Name -eq 'heading' |
                        ForEach-Object Value
                }

                $i = $i + 1
            }
        }

        $storyPath = Get-Item "$PsScriptRoot/../res/chattel.setting.json" |
            Get-Content |
            ConvertFrom-Json |
            ForEach-Object { Join-Path $_.NotebookPath 'story.md' }
    }

    Process {
        $row = @{
            Id = Get-Date -f 'yyyy-MM-dd-HHmmss' # Uses DateTimeFormat
            ItemId = $ItemId
            start = if ($Start) { $Start } else { Get-Date -f 'yyyy-MM-dd' } # Uses DateTimeFormat
            end = if ($End) { $End } else { $null }
            what = $What
        }
        
        $append, $content =
            Get-ChattelRow `
                -Row $row `
                -FilePath $storyPath `
                -HeadingName 'story' `
                -WhatIf:$WhatIf |
            ForEach-Object { $_.Append, $_.Content }

        return [pscustomobject]@{
            Path = $storyPath |
                Get-Item
            Line = $line
            LineNumber = $storyPath |
                Get-Item |
                Get-Content |
                Measure-Object -Count
            Info = Get-Headings -StoryPath $storyPath |
                ForEach-Object {
                    $orderedRow | Add-Member `
                        -MemberType NoteProperty `
                        -Name $_ `
                        -Value $row[$_]
                }
        }
    }
}

function Get-ChattelTimeItem {
    Param(
        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true
        )]
        [Alias('Id')]
        [string]
        $ItemId,

        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )

            $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

            "$PsScriptRoot/../res/chattel.setting.json" |
                Get-Item |
                Get-Content |
                ConvertFrom-Json |
                ForEach-Object { Join-Path $_.NotebookPath 'item/*.md' } |
                Get-ChildItem |
                Select-String "(?<=^\s*##\s+)\S.*$" |
                ForEach-Object Matches |
                ForEach-Object Value |
                Select-Object -Unique |
                Where-Object { $_ -like "$WordToComplete*" } |
                ForEach-Object { $CompletionResults.Add($_) } |
                Out-Null

            return $CompletionResults
        })]
        [string[]]
        $TableName
    )

    Process {
        if (-not $ItemId) {
            return
        }

        $tree = "$PsScriptRoot/../res/chattel.setting.json" |
            Get-Item |
            Get-Content |
            ConvertFrom-Json |
            ForEach-Object { Join-Path $_.NotebookPath 'item' } |
            ForEach-Object { Join-Path $_ "item_-_$($ItemId).md" } |
            Get-Item |
            Get-Content |
            Get-MarkdownTree |
            Remove-TrivialBranch |
            ForEach-Object _Table

        if (-not $TableName) {
            return [pscustomobject]@{
                ItemId = $ItemId
                Tree = $tree
            }
        }

        foreach ($name in @(@($TableName) | Where-Object { $_ })) {
            $tree.$name
        }
    }
}

function New-ChattelTimeItem {
    Param(
        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true
        )]
        [Alias('Id')]
        [string]
        $ItemId,

        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )

            $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

            "$PsScriptRoot/../res/chattel.setting.json" |
                Get-Item |
                Get-Content |
                ConvertFrom-Json |
                ForEach-Object { Join-Path $_.NotebookPath 'item/*.md' } |
                Get-ChildItem |
                Select-String "(?<=^\s*##\s+)\S.*$" |
                ForEach-Object Matches |
                ForEach-Object Value |
                Select-Object -Unique |
                Where-Object { $_ -like "$WordToComplete*" } |
                ForEach-Object { $CompletionResults.Add($_) } |
                Out-Null

            return $CompletionResults
        })]
        [string]
        $TableName,

        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )

            $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

            $setting = "$PsScriptRoot/../res/chattel.setting.json" |
                Get-Item |
                Get-Content |
                ConvertFrom-Json

            Set-Variable `
                -Scope Global `
                -Name 'MyTable' `
                -Value $setting.Format.$($FakeBoundParameters['TableName'])

            $setting.Format.$($FakeBoundParameters['TableName']) |
                Where-Object { $_ -like "$WordToComplete*" } |
                ForEach-Object { $CompletionResults.Add($_) } |
                Out-Null

            return $CompletionResults
        })]
        [string]
        $ColumnName,

        [string]
        $CellValue,

        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )

            $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

            $date = Get-Date

            @(@(0 .. 62) + @(-61 .. -1)) |
                ForEach-Object {
                    Get-Date ($date.AddDays($_)) -Format 'yyyy-MM-dd' # Uses DateTimeFormat
                } |
                Where-Object { $_ -like "$wordToComplete*" } |
                ForEach-Object { $CompletionResults.Add($_) } |
                Out-Null

            return $CompletionResults
        })]
        [string]
        $When,

        [switch]
        $WhatIf
    )

    Begin {
        if (-not $When) {
            $When = Get-Date -Format 'yyyy-MM-dd' # Uses DateTimeFormat
        }
    }

    Process {
        if (-not $ItemId) {
            return
        }

        $path = "$PsScriptRoot/../res/chattel.setting.json" |
            Get-Item |
            Get-Content |
            ConvertFrom-Json |
            ForEach-Object { Join-Path $_.NotebookPath 'item' } |
            ForEach-Object { Join-Path $_ "item_-_$($ItemId).md" }
            
        $tree = if (Test-Path $path) {
            $path |
                Get-Item |
                Get-Content |
                Get-MarkdownTree |
                ForEach-Object _Table
        }
        else {
            [pscustomobject]@{
                "item $ItemId" = [pscustomobject]@{}
            }
        }
        
        $itemTree = $tree."item $ItemId"

        $row = @([pscustomobject]@{
            when = $When
            $ColumnName = $CellValue
        })

        if (@($itemTree.PsObject.Properties.Name) -notcontains $TableName) {
            $itemTree | Add-Member `
                -MemberType 'NoteProperty' `
                -Name $TableName `
                -Value $([pscustomobject]@{
                    _Table = $row
                })
        }
        else {
            $itemTree.$TableName._Table += $row
        }

        $output = $tree |
            Write-MarkdownTree `
                -HeadingLevels 2 `
                -WriteTable { Write-ChattelMdTable @args }

        if ($WhatIf) {
            return $output
        }

        $output | Out-File $path
    }
}

function Get-ChattelMatrix {
    Param(
        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )

            $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

            Get-ChattelMatrix |
                Where-Object { $_ -like "*$($WordToComplete.Trim('"'))*" } |
                ForEach-Object { "`"$_`"" } |
                ForEach-Object { $CompletionResults.Add($_) } |
                Out-Null

            return $CompletionResults
        })]
        [string]
        $Name
    )

    # Uses DateTimeFormat
    $idPattern = "\d{4}-\d{2}-\d{2}-\d{6}"

    $path = "$PsScriptRoot/../res/chattel.setting.json" |
        Get-Item |
        Get-Content |
        ConvertFrom-Json |
        ForEach-Object { Join-Path $_.NotebookPath 'matrix/*.md' } |
        Get-Item

    if (-not $Name) {
        return $path |
            Get-Content |
            Get-MarkdownTree |
            ForEach-Object { $_.PsObject.Properties } |
            Where-Object { $_.Name -like "matrix*" } |
            ForEach-Object { $_.Value } |
            ForEach-Object { $_.PsObject.Properties.Name } |
            Where-Object { $_ }
    }

    $path |
        ForEach-Object {
            $root = $_ |
                Get-Content |
                Get-MarkdownTree |
                ForEach-Object { $_.PsObject.Properties }

            if ($root.Name -like "matrix*") {
                $capture = [regex]::Match($root.Name, "^matrix( (?<id>$idPattern))?")
                $id = $capture.Groups['id'].Value

                $branch = $root.Value |
                    ForEach-Object { $_.PsObject.Properties }

                if ($branch.Name -eq $Name) {
                    $table = $branch.Value |
                        Select-Object -First 1 |
                        ForEach-Object _Table

                    [pscustomobject]@{
                        Id = $id
                        Name = $branch.Name
                        Path = $_
                        Table = $table
                    }
                }
            }
        }
}

function New-ChattelMatrixRow {
    Param(
        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true
        )]
        [Alias('Id')]
        [string]
        $ItemId,

        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )

            $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

            Get-ChattelMatrix |
                Where-Object { $_ -like "*$($WordToComplete.Trim('"'))*" } |
                ForEach-Object { "`"$_`"" } |
                ForEach-Object { $CompletionResults.Add($_) } |
                Out-Null

            return $CompletionResults
        })]
        [Parameter(Position = 0)]
        [string]
        $Name,

        [string]
        $User
    )
    
    Begin {
        $commonHeadings = @('itemid', 'when', 'name', 'itemdescriptor')
    }
    
    DynamicParam {
        $commonHeadings = @('itemid', 'when', 'name', 'itemdescriptor')

        if ($Name) {
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            Get-ChattelMatrix -Name $Name |
                ForEach-Object Table |
                Get-Member -MemberType NoteProperty |
                ForEach-Object Name |
                Where-Object { $_.ToLower() -notin $commonHeadings } |
                Where-Object { $_.ToLower() -notin $PsBoundParameters.Keys.ToLower() } |
                ForEach-Object {
                    $paramName = $_
                    $attr = New-Object System.Management.Automation.ParameterAttribute
                    $attrs = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                    $attrs.Add($attr)
                    $param = New-Object System.Management.Automation.RuntimeDefinedParameter($paramName, [string], $attrs)
                    $paramDictionary.Add($paramName, $param)
                }

            return $paramDictionary
        }
    }
    
    End {
        # Uses DateTimeFormat
        $dateTimeFormat = 'ddd yyyy-MM-dd'
        
        $descriptors = [System.Collections.Generic.List[string]]::new()

        Get-ChattelItem -Id $ItemId |
            ForEach-Object Descriptor |
            ForEach-Object { $descriptors.Add($_) } |
            Out-Null
            
        $descriptors.Sort({ return Compare-ChattelDescriptor $args[0] $args[1] })

        $row = [pscustomobject]@{
            ItemId = $ItemId
            When = Get-Date -f $dateTimeFormat
            Name = $Name
            ItemDescriptor = $descriptors |
                Select-Object -First 1
        }

        Get-ChattelMatrix -Name $Name |
            ForEach-Object Table |
            Get-Member -MemberType NoteProperty |
            ForEach-Object Name |
            Where-Object { $_.ToLower() -notin $commonHeadings } |
            ForEach-Object {
                $row | Add-Member `
                    -MemberType NoteProperty `
                    -Name $_ `
                    -Value $PSBoundParameters[$_]
            }
            
        return $row
    }
}

# (karlr 2026-09-13): Please make private
function Get-ChattelSuggestion {
    Param(
        [string]
        $TableName,

        [string]
        $ColumnName,

        [string]
        $WordToComplete
    )
    
    if ($TableName -eq 'item') {
        return "$PsScriptRoot/../res/chattel.setting.json" |
            Get-Item |
            Get-Content |
            ConvertFrom-Json |
            ForEach-Object { Join-Path $_.NotebookPath 'item.md' } |
            Get-Item |
            Get-Content |
            Get-MarkdownTree |
            ForEach-Object 'item' |
            ForEach-Object '_Table' |
            ForEach-Object $ColumnName |
            Where-Object { $_ } |
            Sort-Object |
            Select-Object -Unique |
            Where-Object { $_ -like "$WordToComplete*" } |
            ForEach-Object {
                if ($_ -like "* *") {
                    "`"$_`""
                }
                else {
                    $_
                }
            }
    }

    "$PsScriptRoot/../res/chattel.setting.json" |
        Get-Item |
        Get-Content |
        ConvertFrom-Json |
        ForEach-Object { Join-Path $_.NotebookPath 'item' } |
        ForEach-Object { Join-Path $_ '*.md' } |
        Get-ChildItem |
        Get-Content |
        Get-MarkdownTree |
        Get-NextTree |
        ForEach-Object $TableName |
        ForEach-Object '_Table' |
        ForEach-Object $ColumnName |
        Where-Object { $_ } |
        Sort-Object |
        Select-Object -Unique |
        Where-Object { $_ -like "$WordToComplete*" } |
        ForEach-Object {
            if ($_ -like "* *") {
                "`"$_`""
            }
            else {
                $_
            }
        }
}

function New-ChattelItem {
    Param(
        [string[]]
        $Descriptor,

        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )
            
            $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

            Get-ChattelSuggestion `
                -TableName 'item' `
                -ColumnName 'model' `
                -WordToComplete $WordToComplete |
            ForEach-Object { $CompletionResults.Add($_) } |
            Out-Null
            
            return $CompletionResults
        })]
        [string]
        $Model,
        
        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )
            
            $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

            Get-ChattelSuggestion `
                -TableName 'locate' `
                -ColumnName 'where' `
                -WordToComplete $WordToComplete |
            ForEach-Object { $CompletionResults.Add($_) } |
            Out-Null
            
            return $CompletionResults
        })]
        [string]
        $Location,
        
        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )
            
            $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

            Get-ChattelSuggestion `
                -TableName 'owner' `
                -ColumnName 'who' `
                -WordToComplete $WordToComplete |
            ForEach-Object { $CompletionResults.Add($_) } |
            Out-Null
            
            return $CompletionResults
        })]
        [string]
        $Owner,

        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )

            $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

            $date = Get-Date

            @(@(0 .. 62) + @(-61 .. -1)) |
                ForEach-Object {
                    Get-Date ($date.AddDays($_)) -Format 'yyyy-MM-dd' # Uses DateTimeFormat
                } |
                Where-Object { $_ -like "$wordToComplete*" } |
                ForEach-Object { $CompletionResults.Add($_) } |
                Out-Null

            return $CompletionResults
        })]
        [string]
        $Retrieved,

        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )
            
            $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

            Get-ChattelSuggestion `
                -TableName 'item' `
                -ColumnName 'note' `
                -WordToComplete $WordToComplete |
            ForEach-Object { $CompletionResults.Add($_) } |
            Out-Null
            
            return $CompletionResults
        })]
        [string[]]
        $Note,

        [switch]
        $WhatIf
    )
    
    $id = Get-Date -f 'yyyy-MM-dd-HHmmss' # Uses DateTimeFormat
    
    $row = [PSCustomObject]@{
        id = $id
        descriptor = $Descriptor
        retrieved =
            if ($Retrieved) {
                $Retrieved
            }
            else {
                Get-Date -f 'yyyy-MM-dd' # Uses DateTimeFormat
            }
        model = $Model
        note = $Note
    }
    
    $timeItem = [PSCustomObject]@{
        "item $id" = [PSCustomObject]@{
            owner = [PSCustomObject]@{
                _Table = @(
                    [PSCustomObject]@{
                        when = $Retrieved
                        who = $Owner
                    }
                )
            }

            locate = [PSCustomObject]@{
                _Table = @(
                    [PSCustomObject]@{
                        when = $Retrieved
                        where = $Location
                    }
                )
            }
        }
    }

    $itemRowPath = "$PsScriptRoot/../res/chattel.setting.json" |
        Get-Item |
        Get-Content |
        ConvertFrom-Json |
        ForEach-Object { Join-Path $_.NotebookPath 'item.md' }
        
    $append, $content =
        Get-ChattelRow `
            -Row $row `
            -FilePath $itemRowPath `
            -HeadingName 'item' `
            -WhatIf:$WhatIf |
        ForEach-Object { $_.Append, $_.Content }

    ""
    
    Write-ChattelMessage `
        -Content $content `
        -FilePath 'item.md' `
        -Append:$append `
        -WhatIf:$WhatIf

    ""

    if (-not $WhatIf) {
        $content | Out-File `
            -FilePath $itemRowPath `
            -Append:$append
    }
    
    $timeItemSegment = "item/item_-_$($id).md"

    $timeItemPath = "$PsScriptRoot/../res/chattel.setting.json" |
        Get-Item |
        Get-Content |
        ConvertFrom-Json |
        ForEach-Object { Join-Path $_.NotebookPath $timeItemSegment }

    $content =
        $timeItem |
        Write-MarkdownTree `
            -HeadingLevels 2 `
            -WriteTable { Write-ChattelMdTable @args } |
        Select-Object `
            -SkipLast 1

    Write-ChattelMessage `
        -Content $content `
        -FilePath $timeItemSegment `
        -WhatIf:$WhatIf

    ""

    if (-not $WhatIf) {
        $content | Out-File `
            -FilePath $timeItemPath
    }
}

# (karlr 2026-09-13): Please make private
function Write-ChattelMessage {
    Param(
        [string[]]
        $Content,
        
        [string]
        $FilePath,

        [switch]
        $Append,

        [switch]
        $WhatIf
    )
    
    if (-not $WhatIf) {
        $notebookPath = "$PsScriptRoot/../res/chattel.setting.json" |
            Get-Item |
            Get-Content |
            ConvertFrom-Json |
            ForEach-Object NotebookPath

        $fullPath = Join-Path $notebookPath $FilePath
        $FilePath = $PsStyle.FormatHyperlink($FilePath, $fullPath)
    }

    "$(
        if ($Append) {
            "$($PsStyle.Foreground.Magenta)~ "
        }
        else {
            "$($PsStyle.Foreground.Yellow)+ "
        }
    )$FilePath$($PsStyle.Reset) ($($Content.Count) lines)"

    $Content | ForEach-Object {
        "$($PsStyle.Foreground.Green)  + $_$($PsStyle.Reset)"
    }
}

# (karlr 2026-09-13): Please make private
function Get-ChattelRow {
    Param(
        [pscustomobject]
        $Row,

        $FilePath,

        [string]
        $HeadingName,

        [switch]
        $WhatIf
    )

    if (-not (Test-Path $FilePath) -or (Get-Content $FilePath).Count -eq 0) {
        $content =
            [pscustomobject]@{
                $HeadingName = [pscustomobject]@{
                    _Table = @($Row)
                }
            } |
            Write-MarkdownTree `
                -HeadingLevels 1 `
                -WriteTable { Write-ChattelMdTable @args }
    }
    else {
        $cat = $FilePath |
            Get-Item |
            Get-Content

        $lines = $cat.Count

        while ($lines -le 0 -and $cat[$lines - 1] -match "^\s*$") {
            $lines--
        }
        
        if ($lines -ne $cat.Count) {
            $tree = $cat | Get-MarkdownTree
            $tree.item._Table += @($Row)

            $content = $tree | Write-MarkdownTree `
                -HeadingLevels 1 `
                -WriteTable { Write-ChattelMdTable @args }
        }
        else {
            $content =
                [pscustomobject]@{
                    _Table = @($Row)
                } |
                Write-MarkdownTree `
                    -WriteTable { Write-ChattelMdTable @args }

            $append = $true
        }
    }
    
    if ($append) {
        $content = $content | Select-Object -Skip 2
    }
    
    $content = $content | Select-Object -SkipLast 1
    
    return [pscustomobject]@{
        Append = $append
        Content = $content
    }
}
