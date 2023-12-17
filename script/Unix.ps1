<#
.LINK
Url: <https://stackoverflow.com/questions/5102115/unix-format-files-with-powershell>
Retrieved: 2023_04_09

.LINK
Url: <https://stackoverflow.com/users/2895579/evg656e>
Retrieved: 2023_04_09

.LINK
Url: <https://stackoverflow.com/users/621278/anders-zommarin>
Retrieved: 2023_04_09
#>
function ConvertTo-UnixLineEndings {
    Param(
        $Path
    )

    if ((dir $Path).Length -eq 0) {
        return
    }

    # link
    # - url: <https://stackoverflow.com/users/621278/anders-zommarin>
    # - retrieved: 2023_04_09
    [string]::Join("`n", (cat $Path)) | Set-Content $Path
    $oldBytes = [io.file]::ReadAllBytes($Path)

    if (-not $oldBytes.Length) {
        return
    }

    [byte[]] $newBytes = @(
        0 .. ($oldBytes.Length - 1) |
        where {
            ($oldBytes[$_] -ne [byte][char]"`r") -or
            ($oldBytes[$_ + 1] -ne [byte][char]"`n")
        } |
        foreach {
            $oldBytes[$_]
        }
    )

    [io.file]::WriteAllBytes($Path, $newBytes)
}

<#
.LINK
Url: <https://livebook.manning.com/book/powershell-in-depth/chapter-37/15>
Retrieved: 2023_04_09
#>
function Out-FileUnix {
    [CmdletBinding(
        DefaultParameterSetName = 'ByPath',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium',
        HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=113363'
    )]
    Param(
        [Parameter(
            ParameterSetName = 'ByPath',
            Mandatory = $true,
            Position = 0
        )]
        [string]
        ${FilePath},

        [Parameter(
            ParameterSetName = 'ByLiteralPath',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('PSPath')]
        [string]
        ${LiteralPath},

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('unknown','string','unicode','bigendianunicode','utf8','utf7','utf32','ascii','default','oem')]
        [string]
        ${Encoding},

        [switch]
        ${Append},

        [switch]
        ${Force},

        [Alias('NoOverwrite')]
        [switch]
        ${NoClobber},

        [ValidateRange(2, 2147483647)]
        [int]
        ${Width},

        [switch]
        ${NoNewline},

        [Parameter(ValueFromPipeline = $true)]
        [psobject]
        ${InputObject}
    )

    Begin {
        try {
            $outBuffer = $null

            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand(
                'Microsoft.PowerShell.Utility\Out-File',
                [System.Management.Automation.CommandTypes]::Cmdlet
            )

            $scriptCmd = { & $wrappedCmd @PSBoundParameters }

            $steppablePipeline = $scriptCmd.GetSteppablePipeline(
                $myInvocation.CommandOrigin
            )

            $steppablePipeline.Begin($PSCmdlet)
        }
        catch {
            throw
        }
    }

    Process {
        try {
            $steppablePipeline.Process($_)
        }
        catch {
            throw
        }
    }

    End {
        try {
            $steppablePipeline.End()

            $item = switch ($PSCmdlet.ParameterSetName) {
                'ByPath' {
                    Get-Item $FilePath
                }

                'ByLiteralPath' {
                    $LiteralPath
                }
            }

            ConvertTo-UnixLineEndings $item
        }
        catch {
            throw
        }
    }
}
