<#
    .LINK
        https://www.reddit.com/r/webdev/comments/fzsb5k/any_way_to_convert_webp_to_gif_or_jpg_locally_on/g26vdds/?context=3

    .LINK
        https://www.reddit.com/user/earthiverse/
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
        $Destination
    )

    Begin {
        $setting = cat "$PsScriptRoot/../res/imageprocess.setting.json" `
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

            Write-Progress `
                -Activity "Converting item $($count + 1) of $($list.Count)" `
                -Status "$src  ->  $dst" `
                -PercentComplete (100 * $count/$list.Count)

            & $cmd $src $dst
            $count = $count + 1
        }

        Write-Progress `
            -Activity "Conversion finished." `
            -Completed
    }
}

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
        $setting = cat "$PsScriptRoot/../res/imageprocess.setting.json" `
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

    $setting = cat "$PsScriptRoot/../res/imageprocess.setting.json" `
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

