<#
.DESCRIPTION
Tags: compare copy
#>
function Compare-ItemCopy {
    [CmdletBinding()]
    Param(
        [String]
        $Source,

        [String]
        $Destination
    )

    $Source = if ([String]::IsNullOrWhiteSpace($Source)) {
        (Get-Location).Path
    }
    else {
        (Get-Item -Path $Source).FullName
    }

    $Source = $Source.TrimEnd("\")
    $Destination = $Destination.TrimEnd("\")

    Compare-Object `
        (dir $Source -Recurse).FullName `
        (dir $Destination -Recurse).FullName
}

<#
.DESCRIPTION
Tags: date time
#>
function Get-ItemDateTime {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $Path,

        [ArgumentCompleter({
            return ConvertTo-Suggestion `
                -WordToComplete $args[2] `
                -List $(
                    [System.IO.FileSystemInfo].
                    GetProperties() |
                    foreach { $_.Name } |
                    where { $_ -like "*Time*" }
                )
        })]
        [ValidateScript({
            $_ -in $(
                [System.IO.FileSystemInfo].
                GetProperties() |
                foreach { $_.Name } |
                where { $_ -like "*Time*" }
            )
        })]
        [String[]]
        $Property
    )

    if (-not $Path) {
        return
    }

    switch ($Path) {
        { $_ -is [String] } {
            $Path = Get-Item -Path $Path
        }
    }

    $objProperties =
        $Path.
        PsObject.
        Properties |
        where {
            $_.TypeNameOfValue -eq 'System.DateTime'
        }

    if ($Property) {
        return $(foreach ($subitem in $Property) {
            $objProperties | where {
                $_.Name -like $subitem
            } | foreach {
                $Path.($_.Name)
            }
        })
    }

    $table = [Ordered]@{}

    $objProperties | foreach {
        $table[$_.Name] = $Path.($_.Name)
    }

    $table
}

<#
.DESCRIPTION
Tags: move date folder
#>
function Move-ItemToDateFolder {
    [CmdletBinding()]
    Param(
        [String]
        $Path,

        [ArgumentCompleter({
            return ConvertTo-Suggestion `
                -WordToComplete $args[2] `
                -List $(
                    [System.IO.FileSystemInfo].
                    GetProperties() |
                    foreach { $_.Name } |
                    where { $_ -like "*Time*" }
                )
        })]
        [ValidateScript({
            $_ -in $(
                [System.IO.FileSystemInfo].
                GetProperties() |
                foreach { $_.Name } |
                where { $_ -like "*Time*" }
            )
        })]
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
            mkdir `
                -Path $Dir `
                -Force:$Force `
                -WhatIf:$WhatIf
        }

        gci $Path -File |
        foreach {
            copy `
                -Path $_.FullName `
                -Destination "$Dir\$($_.Name)" `
                -Force:$Force `
                -WhatIf:$WhatIf
        }
    }

    function Start-MoveItem {
        Param(
            [String]
            $Path,

            [ArgumentCompleter({
                return ConvertTo-Suggestion `
                    -WordToComplete $args[2] `
                    -List $(
                        [System.IO.FileSystemInfo].
                        GetProperties() |
                        foreach { $_.Name } |
                        where { $_ -like "*Time*" }
                    )
            })]
            [ValidateScript({
                $_ -in $(
                    [System.IO.FileSystemInfo].
                    GetProperties() |
                    foreach { $_.Name } |
                    where { $_ -like "*Time*" }
                )
            })]
            [String]
            $GroupBy = "CreationTime",

            [Switch]
            $Force,

            [Switch]
            $WhatIf
        )

        $Path = $Path.TrimEnd("\")

        dir $Path -File | foreach {
            $date = $_."$GroupBy".Date

            $subdir = Get-Date `
                -Date $date `
                -Format "yyyy_MM_dd"

            if (-not (Test-Path "$Path\$subdir")) {
                mkdir `
                    -Path "$Path\$subdir" `
                    -Force:$Force `
                    -WhatIf:$WhatIf
            }

            $dest = "$Path\$subdir\$_"
            $properties = $_ | Get-ItemDateTime
            move $_.FullName $dest -Force:$Force -WhatIf:$WhatIf
            $item = dir -Path $dest

            if ($item) {
                $properties.Keys |
                where {
                    (Get-Member -InputObject $item).Name -contains $_
                } |
                foreach {
                    $item.$_ = $properties[$_]
                }
            }
        }
    }

    $backup_dir =
        "$($backup_dir)_$(Get-Date -Format "yyyy_MM_dd_HHmmss")"

    if ($Backup) {
        Copy-FilesToBackup `
            -Path $Path `
            -Dir $backup_dir `
            -Force:$Force `
            -WhatIf:$WhatIf
    }

    Start-MoveItem `
        -Path $Path `
        -Force:$Force `
        -WhatIf:$WhatIf
}
