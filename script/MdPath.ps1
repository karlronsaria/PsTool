class BranchDefinition {
    [scriptblock] $Find = { $true }
    [scriptblock] $Post = { $args[0] }
}

function Find-MdPath {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [pscustomobject]
        $InputObject,
        
        [ValidateSet('code', 'link')]
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

        [Parameter(ParameterSetName = 'ByTreePath')]
        [Parameter(ParameterSetName = 'ByTreePathCustom')]
        [ValidateSet('And', 'Or')]
        [string]
        $Mode = 'Or',

        [switch]
        $Recurse
    )

    Begin {
        function Get-Forest {
            Param(
                [Parameter(ValueFromPipeline = $true)]
                $InputString,

                [scriptblock]
                $Where
            )
            
            Begin {
                $content = @()
            }
                
            Process {
                $content += @($InputString)
            }
            
            End {
                $content | 
                Get-MarkdownTree -AsMarkdown |
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

        $types = @{
            '' = [BranchDefinition]::new()
            'code' = [BranchDefinition]@{
                Find = { $args[0] -is [MarkdownTree.Parse.CodeBlock] }
                Post = { $args[0] }
            }
            'link' = [BranchDefinition]@{
                Find = { $args[0].Content -and $args[0].Content.WhereAll({ $args[0].TokenType -eq 'Hyperlink' }).Count -gt 0 }
                Post = { $args[0].Content[0].Content }
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
        
        switch ($Mode) {
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
                foreach ($subpath in $TreePath) {
                    $forest |
                        Where-Object { $_.TreePath -like "*$subpath*" }
                }
            }
        }
    }
}

New-Alias `
    -Name 'pathto' `
    -Value 'Find-MdPath' `
    -Scope Global `
    -Option ReadOnly `
    -Force
