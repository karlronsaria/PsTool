#Requires -RunAs

<#
.DESCRIPTION
Requires: Neovim, Windows Terminal
Tags: code, snippet, capture
#>
function Save-CodeSnippetCapture {
    Param(
        [Parameter(
            ParameterSetName = 'ByCatWithExtension',
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'ByCatWithLanguage',
            ValueFromPipeline = $true
        )]
        [string]
        $InputObject,

        [Parameter(
            ParameterSetName = 'ByCatWithExtension'
        )]
        [string]
        $Extension,

        [ArgumentCompleter({
            Param($A, $B, $C)

            $names = gc "$PsScriptRoot/../res/markdown-fence.json" |
                ConvertFrom-Json |
                foreach {
                    $_.Extensions.
                       PsObject.
                       Properties.
                       Name
                }

            $suggests = $names |
                where { $_ -like "$C*" }

            $suggests = if (@($suggests).Count -eq 0) {
                $names
            }
            else {
                $suggests
            }

            return $suggests |
                foreach {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                }
        })]
        [Parameter(
            ParameterSetName = 'ByCatWithLanguage'
        )]
        $Language,

        [ArgumentCompleter({
            Param($A, $B, $C)

            $names = gc "$PsScriptRoot/../res/markdown-fence.json" |
                ConvertFrom-Json |
                foreach {
                    $_.Extensions.
                       PsObject.
                       Properties.
                       Value
                }

            $suggests = $names |
                where { $_ -like "$C*" }

            $suggests = if (@($suggests).Count -eq 0) {
                $names
            }
            else {
                $suggests
            }

            return $suggests |
                foreach { ".$_" } |
                foreach {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                }
        })]
        [Parameter(
            ParameterSetName = 'ByDir'
        )]
        [string]
        $Path
    )

    Begin {
        $profile = "Capture Prompt"
        $colMargin = 7
        $rowMargin = 8
        $title = "capture_-_$(gdt)"
        $command = "title $title && nvim"
        $len = 0
        $count = 2
        $lines = @()

        if ($PsCmdlet.ParameterSetName -eq 'ByDir') {
            Get-Item $Path |
            Get-Content |
            foreach {
                $count++

                if ($len -lt $_.Length) {
                    $len = $_.Length
                }
            }
        }
    }

    Process {
        foreach ($line in @($InputObject)) {
            $lines += @($line)
            $count++

            if ($line.Length -gt $len) {
                $len = $line.Length
            }
        }
    }

    End {
        if ($PsCmdlet.ParameterSetName -ne 'ByDir') {
            if (-not $Extension) {
                $Language = $Language.ToLower()

                $Extension = gc "$PsScriptRoot/../res/markdown-fence.json" |
                    ConvertFrom-Json |
                    foreach { $_.Extensions.$Language }

                if (-not $Extension) {
                    $Extension = $Language
                }

                $Extension = ".$Extension"
            }

            $Path = "$($env:temp)/$title$Extension"
            $lines | Out-FileUnix -FilePath $Path
        }

        $command = "$command -u NORC +""normal Go"" +""normal o"" +$ $Path"
        sudo wt --size "$($len + $colMargin),$($count + $rowMargin)" -p "$profile" cmd /k "$command"

        $null = demand access
        $window = $null

        while ($null -eq $window) {
            $window =
                Get-OpenWindow |
                where {
                    $_.Caption -like "*$title*"
                }

            sleep -Mill 100
        }

        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        focusw -Caption $window.Caption
        sleep -Mill 300
        $rect = Get-OpenWindowRect -HandleId $window.HandleId

        $width  = $rect.Width
        $height = $rect.Height
        $left   = $rect.Left
        $top    = $rect.Top

        # link
        # - url: <https://superuser.com/questions/1669700/take-screenshot-on-command-prompt-powershell>
        # - retrieved: 2025_01_29
        $bitmap  = New-Object System.Drawing.Bitmap $width, $height
        $graphic = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphic.CopyFromScreen($left, $top, 0, 0, $bitmap.Size)

        Close-OpenWindow -HandleId $window.HandleId | Out-Null
        return $bitmap
    }
}

