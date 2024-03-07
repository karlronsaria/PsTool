. "$PsScriptRoot/../private/Select.ps1" # todo: consider renaming

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

    $Prefix = if ($Prefix -match "^(\w+:)?\\") {
        $Prefix
    }
    else {
        Join-Path $Directory $Prefix
    }

    $item = "$($Prefix)$(Get-Date -f yyyy_MM_dd)$($Name)"
    New-Item $item
}

class MyUrl {
    [String] $Name
    [String] $Where
    [String[]] $Tag

    MyUrl([PsCustomObject] $obj) {
        $this.Name = $obj.Name
        $this.Where = $obj.Where
        $this.Tag = $obj.Tag

        if (-not $this.Tag) {
            $this.Tag = $obj.Tags
        }

        $obj.
            PsObject.
            Properties |
            where {
                $_.MemberType -eq 'NoteProperty'
            } |
            where {
                $_.Name -notmatch "Name|Where|Tags?"
            } |
            foreach {
                $this | Add-Member `
                    -MemberType NoteProperty `
                    -Name $_.Name `
                    -Value $_.Value
            }
    }
}

function Get-MyUrlLink {
    # [CmdletBinding(DefaultParameterSetName = 'InputByName')]
    [Alias('myurllink')]
    [OutputType([MyUrl])]
    Param(
        [ArgumentCompleter({
            Param($A, $B, $WordToComplete, $CommandAst)

            $setting = (dir "$PsScriptRoot/../res/filesystem.setting.json" |
                cat |
                ConvertFrom-Json).
                LocationFile

            $locations = @()
            $pipelineElements = $CommandAst.Parent.PipelineElements

            if ($null -ne $pipelineElements -and @($pipelineElements).Count -gt 0) {
                $locations = iex $pipelineElements[0].Extent.Text
            }

            if ($null -eq $locations -or @($locations).Count -eq 0) {
                $locations = $setting.Notebooks |
                    Get-Item |
                    cat |
                    ConvertFrom-Json |
                    foreach {
                        $_.Location
                        $_.Locations
                    }
            }

            return $(
                (@($locations.Name) +
                @($locations.Tag) +
                @($locations.Tags)) |
                sort |
                select -Unique -CaseInsensitive | # todo
                where {
                    $_ -like "$WordToComplete*"
                } |
                foreach {
                    if ($_ -match "\s") {
                        "`"$_`""
                    }
                    else {
                        $_
                    }
                }
            )
        })]
        [Parameter(Position = 0)]
        $Tag = @(),

        [ValidateSet('Or', 'And')]
        [String]
        $Mode,

        [Switch]
        $NoExpansion,

        [Switch]
        $ToUnix,

        [Parameter(ValueFromPipeline = $true)]
        [MyUrl[]]
        $InputObject = @()
    )

    Begin {
        $list = @()
    }

    Process {
        $list += @($InputObject)
    }

    End {
        [void] $PsBoundParameters.Remove('InputObject')
        return $(
            $list |
            Get-MyUrl @PsBoundParameters |
            foreach { $_.Where }
        )
    }
}

# todo: consider renaming
function Get-MyUrl {
    # [CmdletBinding(DefaultParameterSetName = 'InputByName')]
    [Alias('myurl')]
    [OutputType([MyUrl])]
    Param(
        [ArgumentCompleter({
            Param($A, $B, $WordToComplete, $CommandAst)

            $setting = (dir "$PsScriptRoot/../res/filesystem.setting.json" |
                cat |
                ConvertFrom-Json).
                LocationFile

            $locations = @()
            $pipelineElements = $CommandAst.Parent.PipelineElements

            if ($null -ne $pipelineElements -and @($pipelineElements).Count -gt 0) {
                $locations = iex $pipelineElements[0].Extent.Text
            }

            if ($null -eq $locations -or @($locations).Count -eq 0) {
                $locations = $setting.Notebooks |
                    Get-Item |
                    cat |
                    ConvertFrom-Json |
                    foreach {
                        $_.Location
                        $_.Locations
                    }
            }

            return $(
                (@($locations.Name) +
                @($locations.Tag) +
                @($locations.Tags)) |
                sort |
                select -Unique -CaseInsensitive | # todo
                where {
                    $_ -like "$WordToComplete*"
                } |
                foreach {
                    if ($_ -match "\s") {
                        "`"$_`""
                    }
                    else {
                        $_
                    }
                }
            )
        })]
        [Parameter(Position = 0)]
        $Tag = @(),

        [ValidateSet('Or', 'And')]
        [String]
        $Mode,

        [Switch]
        $NoExpansion,

        [Switch]
        $ToUnix,

        [Parameter(ValueFromPipeline = $true)]
        [MyUrl[]]
        $InputObject = @()
    )

    Begin {
        $setting = (dir "$PsScriptRoot/../res/filesystem.setting.json" |
            cat |
            ConvertFrom-Json).
            LocationFile

        if (-not $Mode) {
            $Mode = $setting.DefaultMode
        }

        $locations = @()
    }

    Process {
        $locations += @($InputObject)
    }

    End {
        if ($null -eq $locations -or @($locations).Count -eq 0) {
            $locations = $setting.Notebooks |
                Get-Item |
                cat |
                ConvertFrom-Json |
                foreach {
                    $_.Location
                    $_.Locations
                } |
                foreach {
                    [MyUrl]::new($_)
                }
        }

        return $(
            $locations |
            Compare-SetFromList `
                -DifferenceObject $Tag `
                -GroupBy 'Where' `
                -SelectBy 'Name', 'Tag', 'Tags' `
                -Mode $Mode |
            foreach {
                $obj = [PsCustomObject]@{}

                $_.PsObject.Properties |
                where { $_.MemberType -in 'Property', 'NoteProperty' } |
                where { $_.Name -ne 'Where' } |
                foreach {
                    $obj | Add-Member `
                        -MemberType NoteProperty `
                        -Name $_.Name `
                        -Value $_.Value
                }

                $obj | Add-Member `
                    -MemberType NoteProperty `
                    -Name 'Where' `
                    -Value $($(
                        if ($NoExpansion) {
                            $_.Where
                        }
                        else {
                            $value = $_.Where

                            foreach ($capture in [Regex]::Matches($value, "%[^%]+%")) {
                                $value = $value -replace `
                                    $capture, `
                                    (& cmd /c "echo $($capture.Value)")
                            }

                            $psMatches = [Regex]::Matches($value, "\$[^\$\\\/]+")

                            $psMatches |
                            foreach -Begin {
                                $count = 0
                            } -Process {
                                $count = $count + 1

                                Write-Progress `
                                    -Id 1 `
                                    -Activity "Running PS subshell" `
                                    -Status "Expanding $($_.Value)" `
                                    -PercentComplete (100 * $count / $psMatches.Count)

                                $value = $value.Replace(
                                    $_,
                                    (& powershell -NoProfile "$($_.Value)")
                                )
                            }

                            Write-Progress `
                                -Id 1 `
                                -Activity "Running PS subshell" `
                                -PercentComplete 100 `
                                -Complete

                            $value
                        }
                    ) |
                    foreach {
                        $_ -replace $(if ($ToUnix) {
                            "\\", "/"
                        }
                        else {
                            "\/", "\"
                        })
                    })

                [MyUrl]::new($obj)
            }
        )
    }
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

                $name = (Get-Item $name).Name

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

                Write-Progress `
                    -Id 1 `
                    -Activity "Loading quickform" `
                    -Status "Importing module" `
                    -PercentComplete 33

                Import-Module -Name PsQuickform

                Write-Progress `
                    -Id 1 `
                    -Activity "Loading quickform" `
                    -Status "Loading menu" `
                    -PercentComplete 66

                $result = $menu |
                    ConvertFrom-Json |
                    Show-QformMenu

                Write-Progress `
                    -Id 1 `
                    -Activity "Loading quickform" `
                    -PercentComplete 100 `
                    -Complete

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

