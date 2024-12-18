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
                Sort-Object
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

        $diff = diff `
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
                Sort-Object
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
        $PassThru,

        [Switch]
        $WhatIf
    )

    'PassThru', 'WhatIf' |
    foreach {
        [void]$PsBoundParameters.Remove($_)
    }

    Write-Progress `
        -Id 1 `
        -Activity "Import-DemandModule" `
        -Status "Searching demand files" `
        -PercentComplete 0

    foreach ($file in (Get-DemandScript @PsBoundParameters)) {
        if ($PassThru) {
            $file
        }

        Write-Progress `
            -Id 1 `
            -Activity "Import-DemandModule" `
            -Status "File found: $file" `
            -PercentComplete 0

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

    Write-Progress `
        -Id 1 `
        -Activity "Import-DemandModule" `
        -PercentComplete 100 `
        -Complete
}

