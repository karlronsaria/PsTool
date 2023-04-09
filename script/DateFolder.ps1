function Test-ItemCopy {
    [CmdletBinding()]
    Param(
        [String]
        $Source,

        [String]
        $Destination
    )

    $ErrorActionPreference = "Stop"

    if ([String]::IsNullOrWhiteSpace($Source)) {
        $Source = (Get-Location).Path
    } else {
        $Source = (Get-Item -Path $Source).FullName
    }

    $Source = $Source.TrimEnd("\")
    $Destination = $Destination.TrimEnd("\")
    $list = (dir $Source -Recurse).FullName

    return $list | % {
        $_.Replace($Source, $Destination) | ? {
            -not (Test-Path $_)
        }
    }
}

$global:DateTimeProperties = @(
      "CreationTime"
    , "CreationTimeUtc"
    , "LastAccessTime"
    , "LastAccessTimeUtc"
    , "LastWriteTime"
    , "LastWriteTimeUtc"
)

function Get-ItemDateTime {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $Path,

        [ArgumentCompleter({ return $global:DateTimeProperties })]
        [String[]]
        $Property
    )

    if (-not $Path) {
        return
    }

    switch ($Path.GetType().Name) {
        "String" {
            $Path = Get-Item -Path $Path
        }
    }

    $objProperties = $Path.PsObject.Properties | where {
        $_.TypeNameOfValue -eq 'System.DateTime'
    }

    if ($Property) {
        foreach ($subitem in $Property) {
            $objProperties | where {
                $_.Name -like $subitem
            } | foreach {
                Write-Output $Path.($_.Name)
            }
        }
    } else {
        $table = [Ordered]@{}

        $objProperties | foreach {
            $table[$_.Name] = $Path.($_.Name)
        }

        Write-Output $table
    }
}

function Move-ItemToDateFolder {
    [CmdletBinding()]
    Param(
        [String]
        $Path,

        [ArgumentCompleter({ return $global:DateTimeProperties })]
        [String]
        $GroupBy = "CreationTime",

        [Switch]
        $Backup,

        [Switch]
        $Force,

        [Switch]
        $WhatIf
    )

    $ErrorActionPreference = "Stop"

    if (-not $Path) {
        $Path = (Get-Location).Path
    }

    $backup_dir = "$Path\temp"

    function Copy-FilesToBackup {
        Param(
            [String]
            $Path,

            [String]
            $Dir,

            [Switch]
            $Force,

            [Switch]
            $WhatIf
        )

        if (-not (Test-Path $Dir)) {
            mkdir $Dir -Force:$Force -WhatIf:$WhatIf
        }

        gci $Path -File | % {
            copy -Path $_.FullName -Destination "$Dir\$($_.Name)" -Force:$Force -WhatIf:$WhatIf
        }
    }

    function Start-MoveItem {
        Param(
            [String]
            $Path,

            [ValidateSet({ $_ -in $global:DateTimeProperties })]
            [String]
            $GroupBy = "CreationTime",

            [Switch]
            $Force,

            [Switch]
            $WhatIf
        )

        $Path = $Path.TrimEnd("\")

        gci $Path -File | % {
            $date = $_."$GroupBy".Date
            $subdir = Get-Date -Date $date -Format "yyyy_MM_dd"

            if (-not (Test-Path $Path\$subdir)) {
                mkdir $Path\$subdir -Force:$Force -WhatIf:$WhatIf
            }

            $dest = "$Path\$subdir\$_"
            $properties = $_ | Get-ItemDateTime
            move $_.FullName $dest -Force:$Force -WhatIf:$WhatIf
            $item = gci -Path $dest

            if ($item) {
                $properties.Keys | % {
                    if ((Get-Member -InputObject $item).Name -contains $_) {
                        $item.$_ = $properties[$_]
                    }
                }
            }
        }
    }

    $backup_dir = $backup_dir + "_" + (Get-Date -Format "yyyy_MM_dd_HHmmss")

    if ($Backup) {
        Copy-FilesToBackup -Path $Path -Dir $backup_dir -Force:$Force -WhatIf:$WhatIf
    }

    Start-MoveItem -Path $Path -Force:$Force -WhatIf:$WhatIf
}
