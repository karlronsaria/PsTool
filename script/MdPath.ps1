class BranchDefinition {
    [scriptblock] $Find = { $true }
    [scriptblock] $Post = { $args[0] }
}

function Find-MdPath {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,
        
        [ValidateSet('code', 'issue', 'link', 'todo', '__')]
        [Parameter(
            ParameterSetName = 'All',
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'ByTreePath',
            Position = 0
        )]
        [string]
        $Type,
        
        [Parameter(
            ParameterSetName = 'AllCustom',
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'ByTreePathCustom',
            Position = 0
        )]
        [BranchDefinition]
        $CustomType,

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
            
            Find-MdPath @FakeBoundParameters |
                ForEach-Object TreePath |
                Where-Object { $_ -like "*$WordToComplete*" } |
                ForEach-Object { "`"$_`"" } |
                ForEach-Object { $CompletionResults.Add($_) } |
                Out-Null
            
            return $CompletionResults
        })]
        [Parameter(
            ParameterSetName = 'ByTreePath',
            Position = 1
        )]
        [Parameter(
            ParameterSetName = 'ByTreePathCustom',
            Position = 1
        )]
        [string[]]
        $TreePath,
        
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
            
            "$PsScriptRoot/../res/howtotree.setting.json" |
                Get-Item |
                Get-Content |
                ConvertFrom-Json |
                ForEach-Object Notebooks |
                Get-ChildDocumentItem `
                    -Recurse:$Recurse |
                Get-Content |
                Get-MarkdownTree -AsMarkdown |
                ForEach-Object {
                    $_.WhereAll({ $args[0].Name -eq 'tag' })
                } |
                ForEach-Object {
                    $_.ForEach({ $args[0].Children[0].Name })
                } |
                Where-Object { $_ } |
                ForEach-Object { $_.Split("#").Trim() } |
                Where-Object { $_ } |
                Sort-Object |
                Where-Object { $_ -like "*$WordToComplete*" } |
                ForEach-Object {
                    if ($_ -like "* *") {
                        "`"$_`""
                    }
                    else {
                        $_
                    }
                } |
                ForEach-Object { $CompletionResults.Add($_) } |
                Out-Null
                
            return $CompletionResults
        })]
        [string[]]
        $Tag,

        [Parameter(ParameterSetName = 'ByTreePath')]
        [Parameter(ParameterSetName = 'ByTreePathCustom')]
        [ValidateSet('And', 'Or')]
        [string]
        $Mode = 'Or',

        [switch]
        $Recurse
    )

    DynamicParam {
        # # todo: Modify argument completion based on the syntax tree


        # $commonHeadings = @('itemid', 'when', 'name', 'itemdescriptor')

        # if ($Name) {
        #     $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        #     Get-ChattelMatrix -Name $Name |
        #         ForEach-Object Table |
        #         Get-Member -MemberType NoteProperty |
        #         ForEach-Object Name |
        #         Where-Object { $_.ToLower() -notin $commonHeadings } |
        #         Where-Object { $_.ToLower() -notin $PsBoundParameters.Keys.ToLower() } |
        #         ForEach-Object {
        #             $paramName = $_
        #             $attr = New-Object System.Management.Automation.ParameterAttribute
        #             $attrs = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        #             $attrs.Add($attr)
        #             $param = New-Object System.Management.Automation.RuntimeDefinedParameter($paramName, [string], $attrs)
        #             $paramDictionary.Add($paramName, $param)
        #         }

        #     return $paramDictionary
        # }
    }
    
    Begin {
        function Get-Tagged {
            Param(
                [Parameter(ValueFromPipeline = $true)]
                $InputObject,

                [string[]]
                $Tag
            )

            Process {
                if (-not $Tag) {
                    return $InputObject
                }
                
                foreach ($tree in @($InputObject | Where-Object { $_ })) {
                    $tagged = $tree.WhereAll({ $args[0].Name -eq 'tag' })
                    
                    if (-not $tagged) {
                        continue
                    }
                    
                    $tagged |
                    ForEach-Object {
                        $_.ForEach({ $args[0].Children.Name })
                    } |
                    Where-Object { $_ } |
                    ForEach-Object {
                        $_.Split("#").Trim()
                    } |
                    ForEach-Object {
                        if ($_ -in @($Tag)) {
                            $tree
                        }
                    }
                }
            }
        }
        
        function Get-Forest {
            Param(
                [Parameter(ValueFromPipeline = $true)]
                $InputObject,

                [scriptblock]
                $Where
            )
            
            Begin {
                $content = @()
            }
                
            Process {
                $content += @($InputObject)
            }
            
            End {
                $content | 
                ForEach-Object {
                    $tree = $_
                    $tree.PathOfAll($Where)
                } |
                Where-Object { $_ -and $_.Count -gt 0 } |
                ForEach-Object {
                    $path = $_
                    $branch = $tree
                    $index = 0
                    $list = @()

                    while ($branch.Children.Count -gt 0 -and $index -lt $path.Count) {
                        $list += $branch
                        $branch = $branch.Children[$path[$index++]]
                    }

                    if ($list.Count -gt 0) {
                        $lineAbove = $list[-1].Children[$path[$index - 1] - 1]

                        if ($lineAbove.LineType -eq "Paragraph") {
                            $list += $lineAbove
                        }
                    }

                    [pscustomobject]@{
                        Needle = $branch
                        TreePath = $list.Name -join ": "
                    }
                }
            }
        }

        $notebooks = "$PsScriptRoot/../res/howtotree.setting.json" |
            Get-Item |
            Get-Content |
            ConvertFrom-Json |
            ForEach-Object Notebooks
            
        $defaultDefinition = [BranchDefinition]::new()

        $types = @{
            '' = $defaultDefinition
            '__' = $defaultDefinition
            'code' = [BranchDefinition]@{
                Find = { $args[0] -is [MarkdownTree.Parse.CodeBlock] }
                Post = { $args[0] }
            }
            'link' = [BranchDefinition]@{
                Find = { $args[0].Content -and $args[0].Content.WhereAll({ $args[0].TokenType -eq 'Hyperlink' }).Count -gt 0 }
                Post = { $args[0].Content[0].Content }
            }
            'issue' = [BranchDefinition]@{
                Find = { $args[0].Content -match "^issue (\d|-)+$" }
                Post = { $args[0] }
            }
            'todo' = [BranchDefinition]@{
                Find = { $args[0].Completed -eq $false }
                Post = { $args[0] }
            }
        }

        $files = @()
        $forest = @()
    }
    
    Process {
        if ($InputObject -is [System.IO.FileSystemInfo]) {
            $files += @($InputObject | Where-Object { $_ })
        }
        elseif ($InputObject -is [pscustomobject]) {
            $forest += @($InputObject | Where-Object { $_ })
        }
        elseif ($InputObject -is [string]) {
            $files += @($InputObject | Get-ChildDocumentItem -Recurse:$Recurse)
        }
    }

    End {
        $definition = 
            if ($CustomType) {
                $CustomType
            }
            else {
                $types[$Type]
            }
        
        if ($files.Count -eq 0 -and $forest.Count -eq 0) {
            $files = $notebooks |
                Get-ChildDocumentItem `
                    -Recurse:$Recurse
        }
        
        if ($forest.Count -eq 0) {
            $forest = $files |
                ForEach-Object {
                    $file = $_

                    $file |
                    Get-Content |
                    Get-MarkdownTree `
                        -AsMarkdown |
                    Get-Tagged `
                        -Tag:$Tag |
                    Get-Forest `
                        -Where:$definition.Find |
                    ForEach-Object {
                        [pscustomobject]@{
                            TreePath = $_.TreePath
                            Needle = & $definition.Post $_.Needle
                            FilePath = $file
                        }
                    }
                }
        }
        
        if ($PsCmdlet.ParameterSetName -eq 'All') {
            return $forest
        }
        
        $(switch ($Mode) {
            'And' {
                $forest |
                Where-Object {
                    foreach ($subpath in $TreePath) {
                        if ($_.TreePath -notlike "*$subpath*") {
                            return $false
                        }
                    }
                    
                    return $true
                }
            }
            
            'Or' {
                $TreePath |
                ForEach-Object {
                    $subpath = $_

                    $forest |
                        Where-Object { $_.TreePath -like "*$subpath*" }
                }
            }
        }) |
        Sort-Object `
            -Property TreePath `
            -Unique
    }
}

New-Alias `
    -Name 'pathto' `
    -Value 'Find-MdPath' `
    -Scope Global `
    -Option ReadOnly `
    -Force
