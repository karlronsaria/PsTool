function Get-DemandMatch {
    [OutputType([String])]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [System.IO.FileSystemInfo[]]
        $File,

        [String[]]
        $Pattern
    )

    Begin {
        $setting = cat "$PsScriptRoot\..\res\demandscript.setting.json" |
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
        $list += $Pattern |
          foreach {
            $File |
            sls $_ |
            foreach {
              $item = $_.Path

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
                            "`$(`"$(Split-Path $item -Parent)`")"
                        )
                      }

                      $word = $_.Groups['word']

                      if ($word.Success) {
                        $word.Value
                      }
                    }
                  }
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
          }
    }

    End {
        return $(if ($list.Count -eq 0) {
            Get-DemandScript -All |
                Get-DemandMatch
        }
        else {
            $list |
                sort -Property ScriptModule
        })
    }
}

function Get-DemandScript {
    [CmdletBinding(DefaultParameterSetName = 'SomeFiles')]
    [OutputType([System.IO.FileInfo])]
    Param(
        [ArgumentCompleter({
            # todo: Repetetive. Consider cleaning up.
            Param($A, $B, $C)

            $setting =
                cat "$PsScriptRoot\..\res\demandscript.setting.json" |
                ConvertFrom-Json

            $scripts =
                Get-DemandScript -All

            $modules =
                $scripts |
                Split-Path -Parent |
                Split-Path -Parent |
                Split-Path -Leaf

            $other = @()
            $tags = @()

            foreach ($pat in $setting.Patterns) {
              if ($pat.Name -notin $setting.ScriptPatterns) {
                $other += @(
                  $scripts |
                  sls $pat.Value |
                  foreach { $_.Matches.Value }
                )
              }
              else {
                $tags += @(
                  $scripts |
                  sls $pat.Value |
                  foreach {
                    $file = $_.Path

                    $_.Matches | foreach {
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
                  }
                )
              }
            }

            $select =
                $setting.
                Commands.
                Select.
                ($PsVersionTable.PsVersion.Major)

            return $(
                (@($tags) + @($other) + @($modules)) |
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

        # todo: consider returning to 'No Parameters Means All'
        [Parameter(
            ParameterSetName = 'AllFiles'
        )]
        [Switch]
        $All,

        [Switch]
        $AllProfiles,

        $Directory
    )

    $setting = cat "$PsScriptRoot/../res/demandscript.setting.json" |
        ConvertFrom-Json

    switch ($PsCmdlet.ParameterSetName) {
        'AllFiles' {
            if (-not $Directory) {
                $start = iex $setting.DefaultStartingDirectory

                $Directory =
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
                        Join-Path $start $_
                    }
            }

            return $(
                $Directory |
                foreach {
                    Join-Path $_ "*/demand/*.ps1"
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
            cat |
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
        -Directory:$Directory `
        -AllProfiles:$AllProfiles `
        -All |
    Get-DemandMatch |
    group Path |
    where { # todo
        $scriptModule =
            $_.Group.ScriptModule |
            & (iex $select)

        $diff = diff `
            (@($_.Group.Matches) + @($scriptModule)) `
            $InputObject

        $null -eq $diff -or
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
    [OutputType([System.Management.Automation.PsModuleInfo])]
    Param(
        [ArgumentCompleter({
            # todo: Repetetive. Consider cleaning up.
            Param($A, $B, $C)

            $setting =
                cat "$PsScriptRoot\..\res\demandscript.setting.json" |
                ConvertFrom-Json

            $scripts =
                Get-DemandScript -All

            $modules =
                $scripts |
                Split-Path -Parent |
                Split-Path -Parent |
                Split-Path -Leaf

            $other = @()
            $tags = @()

            foreach ($pat in $setting.Patterns) {
              if ($pat.Name -notin $setting.ScriptPatterns) {
                $other += @(
                  $scripts |
                  sls $pat.Value |
                  foreach { $_.Matches.Value }
                )
              }
              else {
                $tags += @(
                  $scripts |
                  sls $pat.Value |
                  foreach {
                    $file = $_.Path

                    $_.Matches | foreach {
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
                  }
                )
              }
            }

            $select =
                $setting.
                Commands.
                Select.
                ($PsVersionTable.PsVersion.Major)

            return $(
                (@($tags) + @($other) + @($modules)) |
                & (iex $select) |
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

