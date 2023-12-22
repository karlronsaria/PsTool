function Get-DemandMatch {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [System.IO.FileSystemInfo[]]
        $InputObject,

        [String[]]
        $Pattern
    )

    Begin {
        if ($Pattern.Count -eq 0) {
            $Pattern =
                (cat "$PsScriptRoot\..\res\demandscript.setting.json" |
                ConvertFrom-Json).
                Patterns.
                Value
        }

        $list = @()
    }

    Process {
        $list += @(foreach ($item in $Pattern) {
            $InputObject |
            sls $item |
            foreach {
                [PsCustomObject]@{
                    Matches =
                        $_.Matches |
                        foreach {
                            $_ -split "\s"
                        } |
                        select -Unique
                    ItemName = Split-Path $_.Path -Leaf
                    ScriptModule =
                        $_.Path |
                        Split-Path -Parent |
                        Split-Path -Parent |
                        Split-Path -Leaf
                    Path = $_.Path
                    Capture = $_
                }
            }
        })
    }

    End {
        return $(if ($list.Count -eq 0) {
            Get-DemandScript |
                Get-DemandMatch
        }
        else {
            $list | sort -Property ScriptModule
        })
    }
}

function Get-DemandScript {
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            $setting =
                cat "$PsScriptRoot\..\res\demandscript.setting.json" |
                ConvertFrom-Json

            $strings =
                Get-DemandScript |
                sls $setting.Patterns.Value |
                foreach { $_.Matches -split "\s" }

            $modules =
                Get-DemandScript |
                Split-Path -Parent |
                Split-Path -Parent |
                Split-Path -Leaf

            return $(
                (@($strings) + @($modules)) |
                select -Unique |
                where { $_ -like "$C*" } |
                sort
            )
        })]
        [Parameter(Position = 0)]
        [String[]]
        $InputObject,

        [ValidateSet('Or', 'And')]
        [String]
        $Mode = 'Or',

        [Switch]
        $AllProfiles
    )

    $setting = cat "$PsScriptRoot/../res/demandscript.setting.json" |
        ConvertFrom-Json

    if ($InputObject.Count -eq 0) {
        return $(
            $(if ($AllProfiles) {
                $setting.Profiles
            }
            else {
                $setting.Profiles |
                where {
                    $_.Version -eq $setting.DefaultVersion
                }
            }).
            Location |
            foreach {
                "$env:OneDrive/Documents/$_/Scripts/*/demand/*.ps1"
            } |
            dir
        )
    }

    Get-DemandScript `
        -AllProfiles:$AllProfiles |
    Get-DemandMatch |
    group Path |
    where {
        $scriptModule =
            $_.Group.ScriptModule |
            select -Unique

        $diff = diff `
            ($_.Group.Matches + @($scriptModule)) `
            $InputObject

        ($Mode -eq 'Or' -or
            $diff.SideIndicator -notcontains '=>') -and
            $diff.Count -lt `
            ($_.Group.Matches.Count + $InputObject.Count)
    } |
    foreach {
        $_.Group.Path
    } |
    select -Unique
}

function Import-DemandModule {
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            $setting =
                cat "$PsScriptRoot\..\res\demandscript.setting.json" |
                ConvertFrom-Json

            $strings =
                Get-DemandScript |
                sls $setting.Patterns.Value |
                foreach { $_.Matches -split "\s" }

            $modules =
                Get-DemandScript |
                Split-Path -Parent |
                Split-Path -Parent |
                Split-Path -Leaf

            return $(
                (@($strings) + @($modules)) |
                select -Unique |
                where { $_ -like "$C*" } |
                sort
            )
        })]
        [Parameter(Position = 0)]
        [String[]]
        $InputObject,

        [ValidateSet('Or', 'And')]
        [String]
        $Mode = 'Or',

        [Switch]
        $AllProfiles,

        [Switch]
        $PassThru,

        [Switch]
        $WhatIf
    )

    'PassThru', 'WhatIf' |
    foreach {
        [void]$PsBoundParameters.Remove($_)
    }

    foreach ($file in (Get-DemandScript @PsBoundParameters)) {
        if ($PassThru) {
            $file
        }

        $dir = (dir $file).Directory

        $script = New-Module `
            -ScriptBlock $(
                [ScriptBlock]::Create((
                    cat $file |
                    foreach {
                        $_ -replace "\`$PsScriptRoot", $dir
                    } |
                    Out-String
                ))
            ) `
            -Name "ModuleOnDemand_$((Get-Item $file).BaseName)"

        if ($WhatIf) {
            $script
        }
        else {
            Import-Module $script
        }
    }
}

