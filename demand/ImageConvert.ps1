<#
.SYNOPSIS
Generates images by batch-conversion using ImageMagick, useful for background images themes
Requires ImageMagick

.TAGS
imagemagick batch convert windows explorer profile theme
#>
function New-WindowsExplorerTheme {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [Object[]]
        $Directory,

        [String]
        $Destination,

        [Switch]
        $WhatIf
    )

    Begin {
        $setting = cat "$PsScriptRoot/../res/imageprocess.setting.json" |
            ConvertFrom-Json

        $app = $setting.AppPath

        $process = $setting.
            Processes |
            where { $_.Name -eq "WindowsExplorer" }

        if ($Directory.Count -eq 0) {
            $Directory = Get-Location
        }

        if ([String]::IsNullOrEmpty($Destination)) {
            $Destination = (Get-Location).Path
        }

        $folders = @(
            "00_convert"
            "01_mogrify"
        )

        mkdir $folders -ErrorAction SilentlyContinue
        $dateTime = Get-Date -f yyyy_MM_dd_HHmmss
    }

    Process {
        dir $Directory -File |
        foreach {
          $dst =
          "$Destination/$($folders[0])/$($_.BaseName)_$dateTime.png"

          $cmd =
          "$app convert $($process.Convert) `"$($_.Name)`" `"$dst`""

          if ($WhatIf) {
              $cmd
          }
          else {
              iex $cmd
          }
        }

        $src = "$Destination/$($folders[0])/*.png"
        $dst = $folders[1]
        $cmd = "$app mogrify -path `"$dst`" $($process.Mogrify) `"$src`""

        if ($WhatIf) {
            $cmd
        }
        else {
            iex $cmd
        }
    }
}
