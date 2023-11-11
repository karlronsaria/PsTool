#Requires -Module PsQuickform

function Rename-AllSansWhiteSpace {
    Param(
        [Parameter(Position = 0)]
        [String]
        $Path = (Get-Location),

        [String]
        $Delimiter = '_',

        [Switch]
        $Force,

        [Switch]
        $WhatIf,

        [Switch]
        $Reverse
    )

    $dir = dir $Path

    if ($Reverse) {
        $match = $Delimiter
        $replace = ' '
    } else {
        $match = '\s'
        $replace = $Delimiter
    }

    Write-Output "Renaming..."
    Write-Output ""

    foreach ($item in $dir) {
        $fullName = $item.FullName
        $name = $item.Name
        $parent = Split-Path $fullName -Parent

        if ($name -match $match) {
            $newName = $name -Replace $match, $replace

            if (-not $WhatIf) {
                Write-Output "  $fullName"
                Write-Output "    -> $newName"
                Write-Output ""
            }

            Rename-Item `
                -Path $fullName `
                -NewName $newName `
                -Force:$Force `
                -WhatIf:$WhatIf
        }
    }
}

function New-NoteItem {
    [Alias('nni')]
    Param(
        [Parameter(Position = 0)]
        [String]
        $Prefix,

        [Parameter(Position = 1)]
        [String]
        $Name,

        [String]
        $Directory = (Get-Location).Path,

        [String]
        $Extension
    )

    $fullFileNamePattern =
        "(?<prefix>\w+)_-_\d{4}(_\d{2}){2}_(?<description>.+)(?<extension>\.\w(\w|\d)*)"

    $fullNameAttempt = if ($Name) {
        $Name
    } elseif ($Prefix) {
        $Prefix
    }

    $capture = [Regex]::Match($fullNameAttempt, $fullFileNamePattern)

    if ($capture.Success) {
        $Prefix = $capture.Groups['prefix'].Value
        $Name = $capture.Groups['description'].Value
        $Extension = $capture.Groups['extension'].Value
    }

    if ($Extension) {
        $Name = "$($Name)$($Extension)"
    }

    $Prefix = if ($Prefix) {
        "$($Prefix)_-_"
    } else {
        ""
    }

    if ($Name -match ".+\.\w(\w|\d)+$") {
        $Name = "_$Name"
    }

    $item =
        Join-Path $Directory "$($Prefix)$(Get-Date -f yyyy_MM_dd)$($Name)"

    New-Item $item
}

function Rename-Item {
    [CmdletBinding(
        DefaultParameterSetName = 'ByPath',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium',
        SupportsTransactions = $true,
        HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=113382'
    )]
    param(
        [Parameter(
            ParameterSetName = 'ByPath',
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]
        ${Path},

        [Parameter(
            ParameterSetName = 'ByLiteralPath',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('PSPath')]
        [string]
        ${LiteralPath},

        [Parameter(
            Position = 1,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]
        ${NewName},

        [switch]
        ${Force},

        [switch]
        ${PassThru},

        [Parameter(
            ValueFromPipelineByPropertyName = $true
        )]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential}
    )

    dynamicparam {
        try {
            $targetCmd = $ExecutionContext.InvokeCommand.GetCommand(
                'Microsoft.PowerShell.Management\Rename-Item',
                [System.Management.Automation.CommandTypes]::Cmdlet,
                $PSBoundParameters
            )

            $dynamicParams = @($targetCmd.Parameters.GetEnumerator() |
                Microsoft.PowerShell.Core\Where-Object {
                    $_.Value.IsDynamic
                }
            )

            if ($dynamicParams.Length -gt 0) {
                $paramDictionary =
                [Management.Automation.RuntimeDefinedParameterDictionary]::
                new()

                foreach ($param in $dynamicParams) {
                    $param = $param.Value

                    if (-not $MyInvocation.MyCommand.Parameters.ContainsKey(
                        $param.Name
                    )) {
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
        } catch {
            throw
        }
    }

    begin {
        try {
            $continue = $true

            if (-not $NewName) {
                $name = switch ($PsCmdlet.ParameterSetName) {
                    'ByPath' { $Path }
                    'ByLiteralPath' { $LiteralPath }
                }

                $menu = @"
{
    "Preferences": { "Caption": "Rename-Item: $name" },
    "MenuSpecs": [
        {
            "Name": "NewName",
            "Type": "Field",
            "Default": "$name"
        }
    ]
}
"@

                $result = $menu | ConvertFrom-Json | Show-QformMenu

                if (-not $result.Confirm) {
                    $continue = $false
                    return
                }

                $answer = $result.MenuAnswers.NewName

                if (-not $answer -or $answer -eq $name) {
                    $continue = $false
                    return
                }

                $PSBoundParameters['NewName'] = $answer
            }

            $outBuffer = $null

            if ($PSBoundParameters.TryGetValue(
                'OutBuffer',
                [ref]$outBuffer
            )) {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand(
                'Microsoft.PowerShell.Management\Rename-Item',
                [System.Management.Automation.CommandTypes]::Cmdlet
            )

            $scriptCmd = { & $wrappedCmd @PSBoundParameters }
            $steppablePipeline =
                $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process {
        try {
            if (-not $continue) {
                return
            }

            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end {
        try {
            if (-not $continue) {
                return
            }

            $steppablePipeline.End()
        } catch {
            throw
        }
    }

<#
.ForwardHelpTargetName Microsoft.PowerShell.Management\Rename-Item
.ForwardHelpCategory Cmdlet
#>
}

