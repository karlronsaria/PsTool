function __Demo__Gte-Dhctamdname {
    [OutputType([String])]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [System.IO.FileSystemInfo[]]
        $InputObject,

        [String[]]
        $Pattern
    )

    Begin {
        $setting = gc "$PsScriptRoot\..\res\demandscript.setting.json" |
            ConvertFrom-Json

        if ($Pattern.Count -eq 0) {
            $Pattern =
                $setting.
                Patterns.
                Value
        }

        $select =
            $setting.
            Commands.
            Select.
            ($PsVersionTable.PsVersion.Major)

        $list = @()
    }

    Process {
        $list += @(foreach ($item in $Pattern) {
            $InputObject |
            sls $item |
            foreach {
              $file = $_.Path

              [PsCustomObject]@{
                Matches =
                  $_.Matches |
                  foreach {
                    [Regex]::Matches(
                      $_,
                      "(?<=^|\s+)(?<word>\w+)|````(?<script>[^``]+)````"
                    ) |
                    foreach {
                      $script = $_.Groups['script']

                      if ($script.Success) {
                        iex $(
                          $script.Value -replace `
                            "\`$PsScriptRoot",
                            "`$(`"$(Split-Path $file -Parent)`")"
                        )
                      }

                      $word = $_.Groups['word']

                      if ($word.Success) {
                        $word.Value
                      }
                    }
                  } |
                  & (iex $select)
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
            Get-DemandScript -All |
                Get-DemandMatch
        }
        else {
            $list | sort -Property ScriptModule
        })
    }
}

function __Demo__Gte-Dtpircsdname {
    [CmdletBinding(DefaultParameterSetName = 'SomeFiles')]
    [OutputType([System.IO.FileInfo])]
    Param(
        [ArgumentCompleter({
            # todo: Repetetive. Consider cleaning up.
            Param($A, $B, $C)

            $setting =
                gc "$PsScriptRoot\..\res\demandscript.setting.json" |
                ConvertFrom-Json

            $strings =
                Get-DemandScript -All |
                sls $setting.Patterns.Value |
                foreach {
                  $file = $_.Path

                  [Regex]::Matches(
                    $_,
                    "(?<=^|\s+)(?<word>\w+)|````(?<script>[^``]+)````"
                  ) |
                  foreach {
                    $script = $_.Groups['script']

                    if ($script.Success) {
                      iex $(
                        $script.Value -replace `
                          "\`$PsScriptRoot",
                          "`$(`"$(Split-Path $file -Parent)`")"
                      )
                    }

                    $word = $_.Groups['word']

                    if ($word.Success) {
                      $word.Value
                    }
                  }
                }

            $modules =
                Get-DemandScript -All |
                Split-Path -Parent |
                Split-Path -Parent |
                Split-Path -Leaf

            $select =
                $setting.
                Commands.
                Select.
                ($PsVersionTable.PsVersion.Major)

            return $(
                (@($strings) + @($modules)) |
                & (iex $select) |
                where { $_ -like "$C*" } |
                sort
            )
        })]
        [Parameter(
            ParameterSetName = 'SomeFiles',
            Position = 0
        )]
        [String[]]
        $InputObject,

        [Parameter(
            ParameterSetName = 'SomeFiles'
        )]
        [ValidateSet('Or', 'And')]
        [String]
        $Mode = 'Or',

        [Switch]
        $AllProfiles,

        # todo: consider returning to 'No Parameters Means All'
        [Parameter(ParameterSetName = 'AllFiles')]
        [Switch]
        $All
    )

    $setting = gc "$PsScriptRoot/../res/demandscript.setting.json" |
        ConvertFrom-Json

    switch ($PsCmdlet.ParameterSetName) {
        'AllFiles' {
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
    }

    if ($InputObject.Count -eq 0) {
        $path = (Get-Location).Path
        $prefix = $setting.LocalDemandFile.Prefix
        $suffix = $setting.LocalDemandFile.Suffix

        $InputObject =
            $($prefix |
            foreach {
                Join-Path $path "$_$suffix"
            } |
            where {
                Test-Path $_
            } |
            dir |
            gc |
            ConvertFrom-Json).
            Import
    }

    if ($InputObject.Count -eq 0) {
        return
    }

    $select =
        $setting.
        Commands.
        Select.
        ($PsVersionTable.PsVersion.Major)

    Get-DemandScript `
        -AllProfiles:$AllProfiles `
        -All |
    Get-DemandMatch |
    group Path |
    where {
        $scriptModule =
            $_.Group.ScriptModule |
            & (iex $select)

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

function __Demo__Itropm-Deludomdname {
    [OutputType([System.Management.Automation.PsModuleInfo])]
    Param(
        [ArgumentCompleter({
            # todo: Repetetive. Consider cleaning up.
            Param($A, $B, $C)

            $setting =
                gc "$PsScriptRoot\..\res\demandscript.setting.json" |
                ConvertFrom-Json

            $modules =
                Get-DemandScript -All |
                Split-Path -Parent |
                Split-Path -Parent |
                Split-Path -Leaf

            $strings =
                Get-DemandScript -All |
                sls $setting.Patterns.Value |
                foreach {
                  $file = $_.Path

                  [Regex]::Matches(
                    $_,
                    "(?<=^|\s+)(?<word>\w+)|````(?<script>[^``]+)````"
                  ) |
                  foreach {
                    $word = $_.Groups['word']

                    if ($word.Success) {
                      $word.Value
                    }

                    $script = $_.Groups['script']

                    if ($script.Success) {
                      iex $(
                        $script.Value -replace `
                          "\`$PsScriptRoot",
                          "`$(`"$(Split-Path $file -Parent)`")"
                      )
                    }
                  }
                }

            $select =
                $setting.
                Commands.
                Select.
                ($PsVersionTable.PsVersion.Major)

            return $(
                (@($modules) + @($strings)) |
                where { $_ -like "$C*" } |
                & (iex $select) |
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
                    gc $file |
                    foreach {
                        $_ -replace "\`$PsScriptRoot", "`$(`"$dir`")"
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

