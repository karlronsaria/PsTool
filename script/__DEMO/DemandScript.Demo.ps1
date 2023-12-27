function Get-DemandMatchWord {
    $setting =
        cat "$PsScriptRoot\..\..\res\demandscript.setting.json" |
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
            "(?<=\s+)(?<word>\w+)|````(?<script>[^``]+)````"
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
        & (iex $select) |
        sort
    )
}

