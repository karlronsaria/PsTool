function Get-HowtoTree {
    [CmdletBinding(DefaultParameterSetName = 'All')]
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
            
            Get-HowtoTree |
                ForEach-Object TreePath |
                Where-Object { $_ -like "*$WordToComplete*" } |
                ForEach-Object { "`"$_`"" } |
                ForEach-Object { $CompletionResults.Add($_) } |
                Out-Null
            
            return $CompletionResults
        })]
        [Parameter(ParameterSetName = 'ByTreePath')]
        [string[]]
        $TreePath,

        [Parameter(ParameterSetName = 'ByTreePath')]
        [ValidateSet('And', 'Or')]
        [string]
        $Mode = 'And'
    )

    $notebooks = "$PsScriptRoot/../res/howtotree.setting.json" |
        Get-Item |
        Get-Content |
        ConvertFrom-Json |
        ForEach-Object Notebooks

    function Get-Forest {
        Param(
            [Parameter(ValueFromPipeline = $true)]
            $InputString
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
                $tree.PathOfAll({ $args[0] -is [MarkdownTree.Parse.CodeBlock] })
            } |
            Where-Object { $_.Count -gt 0 } |
            ForEach-Object {
                $path = $_
                $branch = $tree
                $index = 0
                $list = @()

                while ($branch.Children.Count -gt 0) {
                    $list += $branch
                    $branch = $branch.Children[$path[$index++]]
                }

                if ($list.Count -gt 0 -and $branch -is [MarkdownTree.Parse.CodeBlock]) {
                    $lineAbove = $list[-1].Children[$path[$index - 1] - 1]

                    if ($lineAbove.LineType -eq "Paragraph") {
                        $list += $lineAbove
                    }
                }

                [pscustomobject]@{
                    CodeBlock = $branch
                    TreePath = $list.Name -join ": "
                }
            }
        }
    }
    
    $forest = $notebooks |
        Get-ChildDocumentItem |
        ForEach-Object {
            $file = $_

            $file |
            Get-Content |
            Get-Forest |
            ForEach-Object {
                [pscustomobject]@{
                    TreePath = $_.TreePath
                    CodeBlock = $_.CodeBlock
                    FilePath = $file
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

New-Alias `
    -Name 'Get-HowtoTree' `
    -Value 'howto' `
    -Scope Global `
    -Option ReadOnly `
    -Force
