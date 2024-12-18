function Get-DemandMatchWord {
    $setting =
        gc "$PsScriptRoot\..\..\res\demandscript.setting.json" |
        ConvertFrom-Json

            $scripts =
                Get-DemandScript -All

            $modules =
                Get-DemandScript -All |
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
                Sort-Object
            )
}

