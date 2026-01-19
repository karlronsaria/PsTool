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

    Compare-Object `
        (Get-ChildItem $Source -Recurse).FullName `
        (Get-ChildItem $Destination -Recurse).FullName
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
        [Parameter(ValueFromPipeline = $true)]
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

    Begin {
        function Copy-ItemToBackup {
            Param(
                $InputObject,

                [String]
                $DirName,

                [Switch]
                $Force,

                [Switch]
                $WhatIf
            )

            $item = Get-Item $InputObject
            $path = Split-Path $item.FullName -Parent
            $path = Join-Path $path $DirName

            if (-not (Test-Path $path)) {
                mkdir `
                    -Path $path `
                    -Force:$Force `
                    -WhatIf:$WhatIf
            }

            $dest = Join-Path $path $item.Name

            Copy-Item `
                -Path $item.FullName `
                -Destination $dest `
                -Force:$Force `
                -WhatIf:$WhatIf
        }

        function Start-MoveItem {
            Param(
                $InputObject,

                [String]
                $GroupBy = "CreationTime",

                [Switch]
                $Force,

                [Switch]
                $WhatIf
            )

            $path = Get-Item $InputObject | Split-Path -Parent
            $date = $InputObject."$GroupBy".Date

            $subdir = Get-Date `
                -Date $date `
                -Format "yyyy-MM-dd" # Uses DateTimeFormat

            $path = Join-Path $path $subdir

            if (-not (Test-Path $path)) {
                mkdir `
                    -Path $path `
                    -Force:$Force `
                    -WhatIf:$WhatIf
            }

            $dest = Join-Path $path $InputObject.Name
            $properties = $InputObject | Get-ItemDateTime

            Move-Item `
                -Path $InputObject.FullName `
                -Destination $dest `
                -Force:$Force `
                -WhatIf:$WhatIf

            $item = if ($WhatIf) {
                $null
            }
            else {
                Get-ChildItem -Path $dest
            }

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

        $ErrorActionPreference = "Stop"
        $backupName = "temp_$(Get-Date -Format "yyyy-MM-dd-HHmmss")" # Uses DateTimeFormat
        $list = @()
    }

    Process {
        $list += @(Get-ChildItem $Path)
    }

    End {
        if (@($list | where { $_ }).Count -eq 0) {
            $list = Get-Location |
                foreach Path |
                Get-ChildItem -File
        }

        $list | foreach {
            if ($Backup) {
                Copy-ItemToBackup `
                    -InputObject $_ `
                    -DirName $backupName `
                    -Force:$Force `
                    -WhatIf:$WhatIf
            }

            Start-MoveItem `
                -InputObject $_ `
                -Force:$Force `
                -WhatIf:$WhatIf
        }
    }
}
