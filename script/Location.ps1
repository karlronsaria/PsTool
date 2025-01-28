function Set-Location {
    [CmdletBinding(
        DefaultParameterSetName = 'Path',
        SupportsTransactions = $true,
        HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=113397'
    )]
    Param(
        [Parameter(
            ParameterSetName = 'Path',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]
        ${Path},

        [Parameter(
            ParameterSetName = 'LiteralPath',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('PSPath')]
        [string]
        ${LiteralPath},

        [switch]
        ${PassThru},

        [Parameter(
            ParameterSetName = 'Stack',
            ValueFromPipelineByPropertyName = $true
        )]
        [string]
        ${StackName}
    )

    DynamicParam {
        try {
            $targetCmd = $ExecutionContext.InvokeCommand.GetCommand(
                'Microsoft.PowerShell.Management\Set-Location',
                [System.Management.Automation.CommandTypes]::Cmdlet,
                $PSBoundParameters
            )

            $dynamicParams = @(
                $targetCmd.Parameters.GetEnumerator() |
                Microsoft.PowerShell.Core\Where-Object { $_.Value.IsDynamic }
            )

            if ($dynamicParams.Length -gt 0) {
                $paramDictionary =
                [Management.Automation.RuntimeDefinedParameterDictionary]::new()

                foreach ($param in $dynamicParams) {
                    $param = $param.Value

                    if(-not $MyInvocation.MyCommand.Parameters.ContainsKey($param.Name)) {
                        $dynParam =
                            [Management.Automation.RuntimeDefinedParameter]::new(
                                $param.Name,
                                $param.ParameterType,
                                $param.Attributes
                            )

                        $paramDictionary.Add($param.Name, $dynParam)
                    }
                }

                return $paramDictionary
            }
        }
        catch {
            throw
        }
    }

    Begin {
        try {
            $outBuffer = $null

            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $wrappedCmd =
                $ExecutionContext.InvokeCommand.GetCommand(
                    'Microsoft.PowerShell.Management\Set-Location',
                    [System.Management.Automation.CommandTypes]::Cmdlet
                )

            if ($PsCmdlet.ParameterSetName -in 'Path', 'Literal') {
                $temp = $PsBoundParameters[$PsCmdlet.ParameterSetName]

                if ($temp) {
                    $temp = Resolve-Path $temp -ErrorAction Stop

                    # (karlr 2025_01_19): if file, set location to parent
                    if (-not (Test-Path -Path $temp -PathType Container)) {
                        $temp = Split-Path -Path $temp -Parent
                        $temp = Resolve-Path $_ -ErrorAction Stop
                    }

                    $PsBoundParameters[$PsCmdlet.ParameterSetName] = $temp
                }
            }

            $scriptCmd = { & $wrappedCmd @PSBoundParameters }
            $steppablePipeline =
                $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)

            $doNotProceed = $false
        }
        catch [System.Management.Automation.ItemNotFoundException] {
            # (karlr 2025_01_25): replicate the appearance of a regular cmdlet error message
            $doNotProceed = $true
            Write-Error $_.Exception.ErrorRecord
            return
        }
        catch {
            $doNotProceed = $true
            throw $_
        }
    }

    Process {
        try {
            if ($doNotProceed) {
                return
            }

            # (karlr 2025_01_19): if file, set location to parent
            if ($_) {
                # (karlr 2025_01_25): induce throw when item not found
                $temp = Resolve-Path $_ -ErrorAction Stop

                if (-not (Test-Path -Path $_ -PathType Container)) {
                    $temp = Split-Path -Path $_ -Parent

                    # (karlr 2025_01_25): induce throw when item not found
                    $temp = Resolve-Path $temp -ErrorAction Stop
                }

                $_ = $temp
            }

            $steppablePipeline.Process($_)
        }
        catch [System.Management.Automation.ItemNotFoundException] {
            # (karlr 2025_01_25): replicate the appearance of a regular cmdlet error message
            $doNotProceed = $true
            Write-Error $_.Exception.ErrorRecord
            return
        }
        catch {
            $doNotProceed = $true
            throw $_
        }
    }

    End {
        try {
            if ($doNotProceed) {
                return
            }

            if ($PSBoundParameters.Count -eq 0) {
                (Get-Location).Path
            }
            else {
                Import-DemandModule | Out-Null
            }

            $steppablePipeline.End()
        }
        catch {
            throw
        }
    }

<#
.ForwardHelpTargetName Microsoft.PowerShell.Management\Set-Location
.ForwardHelpCategory Cmdlet
#>
}
