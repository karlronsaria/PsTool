<#
.DESCRIPTION
Tags: oth imagemagick image convert webp

.LINK
Url: <https://www.reddit.com/r/webdev/comments/fzsb5k/any_way_to_convert_webp_to_gif_or_jpg_locally_on/g26vdds/?context=3>
Retrieved: 2023-10-16

.LINK
Url: <https://www.reddit.com/user/earthiverse/>
Retrieved: 2023-10-16
#>
function __Demo__Cmorftrevno-Ipbewegam {
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
        $setting = gc "$PsScriptRoot/../res/imageconvert.setting.json" `
            | ConvertFrom-Json

        $cmd = $setting.AppPath
        $list = @()

        if (-not (Get-Command $cmd -ea Silent)) {
            Write-Output "Requires ImageMagick to be installed on this device."
            return
        }

        if ($Destination -and -not (Test-Path $Destination)) {
            Write-Output "Destination directory not found."
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
                [PsCustomObject]@{
                    Source = $src
                    Destination = $dst
                }
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
Tags: what imagemagick image convert resize
#>
function __Demo__Gte-Ieziseregam {
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
        $setting = gc "$PsScriptRoot/../res/imageconvert.setting.json" `
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
Tags: the imagemagick image convert icon ico
#>
function __Demo__Nwe-Inociegam {
    [CmdletBinding()]
    Param(
        [String]
        $FilePath,

        [Switch]
        $RemoveTemps,

        [Switch]
        $NoExplorer
    )

    $setting = gc "$PsScriptRoot/../res/imageconvert.setting.json" `
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
Tags: tho imagemagick batch convert profile theme ``(gc "$PsScriptRoot/../res/imageconvert.setting.json" | ConvertFrom-Json).Processes.Tags``
#>
function __Demo__Nwe-Itrevnocegam {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [Object[]]
        $Directory,

        [ArgumentCompleter({
            Param($A, $B, $C)

            return $(
                (gc "$PsScriptRoot/../res/imageconvert.setting.json" |
                ConvertFrom-Json).
                Processes.
                Name |
                where { $_ -like "$C*" }
            )
        })]
        [ValidateScript({
            return $($_ -in (
                (gc "$PsScriptRoot/../res/imageconvert.setting.json" |
                ConvertFrom-Json).
                Processes.
                Name
            ))
        })]
        [String]
        $Profile,

        [String]
        $Destination,

        [Switch]
        $WhatIf
    )

    Begin {
        $setting = gc "$PsScriptRoot/../res/imageconvert.setting.json" |
            ConvertFrom-Json

        $app = $setting.AppPath

        $process = $setting.
            Processes |
            where { $_.Name -eq $Profile }

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
        $dateTime = Get-Date -f yyyy-MM-dd-HHmmss # Uses DateTimeFormat
        $list = @()
    }

    Process {
        $list += @(dir $Directory -File)
    }

    End {
        if ($process.Convert) {
            $list |
            foreach -Begin {
              $count = 0
            } -Process {
              $dst =
              "$Destination/$($folders[0])/$($_.BaseName)_$dateTime.png"

              $cmd =
              "$app convert $($process.Convert) `"$($_.Name)`" `"$dst`""

              $progress = @{
                Id = 1
                Activity =
                  "Converting item $($count + 1) of $($list.Count)"
                Status =
                  $_.Name
                PercentComplete =
                  (100 * $count/($list.Count + 2))
              }

              Write-Progress @progress
              $count = $count + 1

              if ($WhatIf) {
                $cmd
              }
              else {
                iex $cmd
              }
            }
        }

        if ($process.Mogrify) {
            $src = "$Destination/$($folders[0])/*.png"
            $dst = $folders[1]
            $cmd = "$app mogrify -path `"$dst`" $($process.Mogrify) `"$src`""

            $progress = @{
              Id = 1
              Activity =
                "Mogrifying items in $dst"
              Status =
                "$(Split-Path $dst -Leaf)"
              PercentComplete =
                (100 * $count/($list.Count + 2))
            }

            Write-Progress @progress

            if ($WhatIf) {
              $cmd
            }
            else {
              iex $cmd
            }
        }

        Write-Progress `
            -Id 1 `
            -Activity "Image convert" `
            -Status "Complete" `
            -PercentComplete 100 `
            -Complete
    }
}
