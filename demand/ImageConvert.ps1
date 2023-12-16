<#
.DESCRIPTION
Tags: imagemagick image convert webp

.LINK
Url: <https://www.reddit.com/r/webdev/comments/fzsb5k/any_way_to_convert_webp_to_gif_or_jpg_locally_on/g26vdds/?context=3>
Retrieved: 2023_10_16

.LINK
Url: <https://www.reddit.com/user/earthiverse/>
Retrieved: 2023_10_16
#>
function ConvertFrom-ImageWebp {
    [CmdletBinding()]
    Param(
        [Parameter(
            ParameterSetName = "ByFilePath",
            ValueFromPipeline = $true
        )]
        [String]
        $Path,

        [Parameter(
            ParameterSetName = "ByDirectory"
        )]
        [String]
        $Directory,

        [Parameter(
            ParameterSetName = "ByFileObject",
            ValueFromPipeline = $true
        )]
        [IO.FileInfo]
        $File,

        [String]
        $Destination,

        [Switch]
        $WhatIf,

        [Switch]
        $PassThru
    )

    Begin {
        $setting = cat "$PsScriptRoot/../res/imageconvert.setting.json" `
            | ConvertFrom-Json

        $cmd = $setting.AppPath
        $list = @()
        $proceed = $true

        if (-not (Get-Command $cmd -ea Silent)) {
            Write-Output "Requires ImageMagick to be installed on this device."
            $proceed = $false
        }

        if ($Destination) {
            if (-not (Test-Path $Destination)) {
                Write-Output "Destination directory not found."
                $proceed = $false
            }
        }

        if (-not $proceed) {
            return
        }
    }

    Process {
        switch ($PsCmdlet.ParameterSetName) {
            "ByFilePath" {
                ConvertFrom-ImageWebp `
                    -File (Get-Item $Path) `
                    -Destination $Destination
            }

            "ByDirectory" {
                Get-ChildItem `
                    -Path $Directory `
                    -Recurse `
                    -Include *.webp `
                | ConvertFrom-ImageWebp `
                    -Destination $Destination
            }

            "ByFileObject" {
                if ($File) {
                    $list += $File
                }
            }
        }
    }

    End {
        $count = 0

        foreach ($file in $list) {
            if (-not ($Destination)) {
                $Destination = $file.DirectoryName
            }

            $frames = (& $cmd identify $file.FullName).Count
            $src = $file.FullName

            $dst = if ($frames -eq 1) {
                "$Destination\$($file.BaseName).png"
            } elseif ($frames -gt 1) {
                "$Destination\$($file.BaseName).gif"
            }

            $progress = @{
                Activity =
                    "Converting item $($count + 1) of $($list.Count)"
                Status =
                    "$src  ->  $dst"
                PercentComplete =
                    (100 * $count/$list.Count)
            }

            Write-Progress @progress
            $command = "$cmd $src $dst"

            if ($WhatIf) {
                $command
            }
            else {
                iex $command
            }

            if ($PassThru) {
                $dst
            }

            $count = $count + 1
        }

        Write-Progress `
            -Activity "Conversion finished." `
            -Completed
    }
}

<#
.DESCRIPTION
Tags: imagemagick image convert resize
#>
function Get-ImageResize {
    [CmdletBinding()]
    Param(
        [Parameter(
            ValueFromPipeline = $true
        )]
        [String]
        $Path,

        [Int]
        $Size,

        [Switch]
        $WhatIf
    )

    Begin {
        $setting = cat "$PsScriptRoot/../res/imageconvert.setting.json" `
            | ConvertFrom-Json

        $app = $setting.AppPath
    }

    Process {
        $cap = [Regex]::Match($Path, "^(?<name>.*)\.(?<ext>[^\.]+)$")
        $name = $cap.Groups['name']
        $ext = $cap.Groups['ext']

        $itemName = if ($cap.Success) {
            "$name-$Size.$ext"
        } else {
            "$Path-$Size"
        }

        $cmd = "$app convert `"$Path`" -resize $Size `"$itemName`""

        if ($WhatIf) {
            return $cmd
        }

        iex $cmd
        dir $itemName
    }
}

<#
.DESCRIPTION
Tags: imagemagick image convert icon ico
#>
function New-ImageIcon {
    [CmdletBinding()]
    Param(
        [String]
        $FilePath,

        [Switch]
        $RemoveTemps,

        [Switch]
        $NoExplorer
    )

    $setting = cat "$PsScriptRoot/../res/imageconvert.setting.json" `
        | ConvertFrom-Json

    $command = $setting.AppPath

    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        return ([PsCustomObject]@{
            Success = $false
            Result =
                "This script requires $command to be available on the machine"
            ItemPath = $FilePath
        })
    }

    if (-not (Test-Path $FilePath)) {
        return ([PsCustomObject]@{
            Success = $false
            Result = "File not found"
            ItemPath = $FilePath
        })
    }

    $dir = Get-Date -Format $setting.DateTimeFormat
    mkdir $dir -Force | Out-Null

    foreach ($size in 16, 32, 48, 128, 256) {
        . $command convert "$($FilePath)" -scale $size "$dir/$size.png"
    }

    $FilePath = (($FilePath -Replace "\.[^\.]+$") + ".ico")
    . $command convert "$dir/*.png" $FilePath

    if ($RemoveTemps) {
        del $dir -Recurse -Force
    }

    if (-not $NoExplorer) {
        Invoke-Item .
    }

    $result = Test-Path $FilePath

    return ([PsCustomObject]@{
        Success = $result
        Result = if ($result) {
                "New file created"
            } else {
                "File could not be created"
            }
        ItemPath = $FilePath
    })
}

<#
.SYNOPSIS
Generates images by batch-conversion using ImageMagick, useful for background images themes
Requires ImageMagick

.Description
Tags: imagemagick batch convert windows explorer profile theme
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
        $setting = cat "$PsScriptRoot/../res/imageconvert.setting.json" |
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
