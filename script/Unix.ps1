<#
    .LINK
        https://stackoverflow.com/questions/5102115/unix-format-files-with-powershell

    .LINK
        https://stackoverflow.com/users/2895579/evg656e

    .LINK
        https://stackoverflow.com/users/621278/anders-zommarin
#>
function ConvertTo-LinuxLineEndings($path) {
    if ((gci $path).Length -eq 0) {
        return
    }

    # https://stackoverflow.com/users/621278/anders-zommarin
    [string]::Join("`n", (cat $path)) | Set-Content $path

    $oldBytes = [io.file]::ReadAllBytes($path)

    if (!$oldBytes.Length) {
        return
    }

    [byte[]] $newBytes = @()
    [byte[]]::Resize([ref]$newBytes, $oldBytes.Length)
    $newLength = 0

    for ($i = 0; $i -lt $oldBytes.Length - 1; $i++) {
        if (($oldBytes[$i] -eq [byte][char]"`r") -and ($oldBytes[$i + 1] -eq [byte][char]"`n")) {
            continue;
        }

        $newBytes[$newLength++] = $oldBytes[$i]
    }

    $newBytes[$newLength++] = $oldBytes[$oldBytes.Length - 1]
    [byte[]]::Resize([ref]$newBytes, $newLength)
    [io.file]::WriteAllBytes($path, $newBytes)
}

<#
    .LINK
        https://livebook.manning.com/book/powershell-in-depth/chapter-37/15
#>
function Out-FileUnix {
    [CmdletBinding(DefaultParameterSetName='ByPath', SupportsShouldProcess=$true, ConfirmImpact='Medium', HelpUri='https://go.microsoft.com/fwlink/?LinkID=113363')]
    param(
        [Parameter(ParameterSetName='ByPath', Mandatory=$true, Position=0)]
        [string]
        ${FilePath},

        [Parameter(ParameterSetName='ByLiteralPath', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('PSPath')]
        [string]
        ${LiteralPath},

        [Parameter(Position=1)]
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

        [Parameter(ValueFromPipeline=$true)]
        [psobject]
        ${InputObject}
    )

    begin {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Out-File', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        }
        catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        }
        catch {
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()

            switch ($PSCmdlet.ParameterSetName) {
                'ByPath' {
                    ConvertTo-LinuxLineEndings (Get-Item $FilePath)
                }

                'ByLiteralPath' {
                    ConvertTo-LinuxLineEndings $LiteralPath
                }
            }
        }
        catch {
            throw
        }
    }
}
