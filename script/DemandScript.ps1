. "$PsScriptRoot/$($PsVersionTable.PsVersion.Major)/Command.ps1"

function Get-DemandMatch {
    [OutputType([String])]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [System.IO.FileSystemInfo[]]
        $File,

        [String[]]
        $Pattern = @()
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
                ItemName = (Get-Item $_.Path).BaseName
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
                Get-DemandMatch -Pattern $Pattern
        }
        else {
            $list |
                Sort-Object -Property ScriptModule
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
                gc "$PsScriptRoot\..\res\demandscript.setting.json" |
                ConvertFrom-Json

            $scripts =
                Get-DemandScript -All

            $submodules = (Get-Item $scripts).BaseName

            # todo
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

            return $(
                (@($tags) + @($other) + @($modules) + @($submodules)) |
                Select-CaseInsensitive |
                where { $_ -like "$C*" } |
                Sort-Object |
                foreach {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                }
            )
        })]
        [Parameter(
            ParameterSetName = 'SomeFiles',
            Position = 0
        )]
        [String[]]
        $InputObject = @(),

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

    $setting = gc "$PsScriptRoot/../res/demandscript.setting.json" |
        ConvertFrom-Json

    switch ($PsCmdlet.ParameterSetName) {
        'AllFiles' {
            if (-not $Directory) {
                $start = iex $setting.DefaultStartingDirectory.$($PsVersionTable.Platform)
                $profiles = $setting.Profiles.$($PsVersionTable.Platform)

                $Directory =
                    $(if ($AllProfiles) {
                        $profiles
                    }
                    else {
                        $profiles |
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

        $InputObject = @(
            $prefix |
            foreach {
                Join-Path $path "$_$suffix"
            } |
            where {
                Test-Path $_
            } |
            dir |
            gc |
            ConvertFrom-Json |
            foreach {
                $_.Import
            }
        )
    }

    if (@($InputObject).Count -eq 0) {
        return
    }

    Get-DemandScript `
        -Directory:$Directory `
        -AllProfiles:$AllProfiles `
        -All |
    Get-DemandMatch |
    group Path |
    where {
        $module = @(
            @($_.Group.ScriptModule) +
            @((dir $_.Group.Path).BaseName)
        ) |
        Select-CaseInsensitive

        # (karlr 2024_02_22): Nil values are being introduced into ``ReferenceObject``
        # by this point.
        $list = @($_.Group.Matches | where { $_ }) + @($module)

        $diff = Compare-Object `
            -Reference $list `
            -Difference $InputObject

        if ($null -eq $diff) {
            $true
        }
        else {
            if ($Mode -eq 'And') {
                $diff.SideIndicator -notcontains '=>'
            }

            if ($Mode -eq 'Or') {
                $diff.Count -lt ($list.Count + @($InputObject).Count)
            }
        }
    } |
    foreach {
        $_.Group.Path
    } |
    select -Unique
}

function Import-DemandModule {
    [Alias('Demand')]
    [OutputType([System.Management.Automation.PsModuleInfo])]
    Param(
        [ArgumentCompleter({
            # todo: Repetetive. Consider cleaning up.
            Param($A, $B, $C)

            $setting =
                gc "$PsScriptRoot\..\res\demandscript.setting.json" |
                ConvertFrom-Json

            $scripts =
                Get-DemandScript -All

            $submodules = (Get-Item $scripts).BaseName

            # todo
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

            return $(
                (@($tags) + @($other) + @($modules) + @($submodules)) |
                Select-CaseInsensitive |
                where { $_ -like "$C*" } |
                Sort-Object |
                foreach {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                }
            )
        })]
        [Parameter(Position = 0)]
        [String[]]
        $InputObject = @(),

        [ValidateSet('Or', 'And')]
        [String]
        $Mode = 'Or',

        [Switch]
        $AllProfiles,

        [Switch]
        $WhatIf
    )

    # (karlr 2025_01_03): new best practice
    $params = $PsBoundParameters

    $threshold = (gc "$PsScriptRoot/../res/demandscript.setting.json" |
        ConvertFrom-Json).
        RequiresLineNumberThreshold

    'WhatIf' |
    foreach {
        [void]$params.Remove($_)
    }

    $activity = "Import-DemandModule"

    Write-Progress `
        -Id 1 `
        -Activity $activity `
        -Status "Searching demand files" `
        -PercentComplete 0

    foreach ($file in (Get-DemandScript @params)) {
        Write-Progress `
            -Id 1 `
            -Activity $activity `
            -Status "File found: $file" `
            -PercentComplete 0

        $dir = (dir $file).Directory
        $baseName = (Get-Item $file).BaseName
        $moduleName = "ModuleOnDemand_$baseName" `

        $lines =
            gc $file |
            foreach {
                $_ -replace "\`$PsScriptRoot", "`$(`"$dir`")"
            }

        $requiresSudo = $null -ne $($lines[0 .. ($threshold - 1)] |
            Select-String "^\s*#Requires -RunAs")

        $script = $lines | Out-String

        $block = New-Module `
            -ScriptBlock $([ScriptBlock]::Create($script)) `
            -Name $moduleName `
            -Alias * `
            -Global

        if ($WhatIf) {
            $block
        }
        else {
            if ($requiresSudo) {
                # link: Command-line Safety Tricks
                # - url
                #   - <https://serverfault.com/questions/11320/command-line-safety-tricks/29261#29261>
                #   - <https://serverfault.com/questions/95431/in-a-powershell-script-how-can-i-check-if-im-running-with-administrator-privil>
                # - retrieved: 2025_02_15
                $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
                $currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
                $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

                if (-not $isAdmin) {
                    Write-Error "This script has a ""#Requires -RunAs"" line. The requested module will not run properly unless you use an elevated prompt."
                }
            }

            Import-Module $block

            $list = Get-Module $moduleName |
                Foreach-Object { $_.ExportedCommands.Keys } |
                Select-Object -Unique

            # (karlr 2025_01_20): output more information by default
            [PsCustomObject]@{
                Script = $baseName
                RequiresSudo = $requiresSudo
                Commands = $list
                ModuleName = $moduleName
                Location = $file
            }
        }
    }

    Write-Progress `
        -Id 1 `
        -Activity $activity `
        -PercentComplete 100 `
        -Complete
}

