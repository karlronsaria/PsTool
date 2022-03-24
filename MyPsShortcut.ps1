
$scripts = dir "$PsScriptRoot\script\*.ps1"

foreach ($script in $scripts) {
    . $script
}

<#
function Start-Sleep {
    [CmdletBinding(DefaultParameterSetName='Seconds', HelpUri='https://go.microsoft.com/fwlink/?LinkID=113407')]
    param(
        [Parameter(ParameterSetName='Seconds', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateRange(0, 35791)]
        [int]
        ${Minutes},

        [Parameter(ParameterSetName='Seconds', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateRange(0, 2147483)]
        [int]
        ${Seconds},

        [Parameter(ParameterSetName='Milliseconds', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateRange(0, 2147483647)]
        [int]
        ${Milliseconds}
    )

    begin
    {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $PSBoundParameters.Remove('Minutes') | Out-Null

            switch ($PSCmdlet.ParameterSetName)
            {
                'Seconds'
                {
                    $Seconds = $PSBoundParameters['Seconds']

                    if ($Seconds -gt 0)
                    {
                        $Seconds += 60 * $Minutes
                    }
                    else
                    {
                        $Seconds = 60 * $Minutes
                    }

                    $PSBoundParameters['Seconds'] = $Seconds
                }
            }

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Start-Sleep', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
    #>
    <#

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Start-Sleep
    .ForwardHelpCategory Cmdlet

    #>
<#
}
#>


