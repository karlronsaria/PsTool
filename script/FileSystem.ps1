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
