function Set-Clipboard {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium', HelpUri='https://go.microsoft.com/fwlink/?LinkId=2109826')]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        ${Value},

        [switch]
        ${Append},

        [switch]
        ${PassThru},

        [Alias('ToLocalhost')]
        [switch]
        ${AsOSC52}
    )

    begin {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand(
                'Microsoft.PowerShell.Management\Set-Clipboard',
                [System.Management.Automation.CommandTypes]::Cmdlet
            )

            $scriptCmd = { & $wrappedCmd @PSBoundParameters }

            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)

            $proceed = $true
        } catch {
            throw
        }
    }

    process {
        try {
            if (-not $proceed) {
                return
            }

            if ($Value -is [System.Drawing.Bitmap]) {
                Add-Type -AssemblyName System.Windows.Forms
                [Windows.Forms.Clipboard]::SetImage([System.Drawing.Bitmap]$Value)
                $proceed = $false
                return
            }

            $_ = $_.ToString()
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end {
        try {
            if (-not $proceed) {
                return
            }

            $steppablePipeline.End()
        } catch {
            throw
        }
    }

    clean {
        if ($proceed -and $null -ne $steppablePipeline) {
            $steppablePipeline.Clean()
        }
    }

<#
.ForwardHelpTargetName Microsoft.PowerShell.Management\Set-Clipboard
.ForwardHelpCategory Cmdlet
#>
}
