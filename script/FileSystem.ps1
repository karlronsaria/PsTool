function Rename-AllSansWhiteSpace {
    Param(
        [Parameter(Position = 0)]
        [String]
        $Path = (Get-Location),

        [String]
        $Delimiter = '_',

        [Switch]
        $Force,

        [Switch]
        $WhatIf
    )

    $dir = dir $Path

    Write-Output "Renaming..."
    Write-Output ""

    foreach ($item in $dir) {
        $fullName = $item.FullName
        $name = $item.Name
        $parent = Split-Path $fullName -Parent

        if ($name -match '\s') {
            $newName = $name -Replace '\s', $Delimiter

            if (-not $WhatIf) {
                Write-Output "  $fullName"
                Write-Output "    -> $newName"
                Write-Output ""
            }

            Rename-Item `
                -Path $fullName `
                -NewName $newName `
                -Force:$Force `
                -WhatIf:$WhatIf
        }
    }
}

function New-NoteItem {
    [Alias('nni')]
    Param(
        [Parameter(Position = 0)]
        [String]
        $Prefix,

        [Parameter(Position = 1)]
        [String]
        $Name,

        [String]
        $Directory = (Get-Location).Path,

        [String]
        $Extension
    )

    if ($Extension) {
        $Name = "$($Name)$($Extension)"
    }

    $Prefix = if ($Prefix) {
        "$($Prefix)_-_"
    } else {
        ""
    }

    if ($Name -match ".+\.\w(\w|\d)+$") {
        $Name = "_$Name"
    }

    $item =
        Join-Path $Directory "$($Prefix)$(Get-Date -f yyyy_MM_dd)$($Name)"

    New-Item $item
}

