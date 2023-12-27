function __Demo__Nwe-Ryrotceridecruose {
    # Needed for ``-ErrorAction SilentyContinue``
    [CmdletBinding()]
    Param(
        [String]
        $BasePath = (Get-Location).Path,

        [String]
        $FolderName,

        [Switch]
        $WhatIf
    )

    if ([String]::IsNullOrWhiteSpace($FolderName)) {
        $FolderName = $setting.ResourceDir
    }

    $BasePath = Join-Path $BasePath $FolderName

    if (-not (Test-Path $BasePath)) {
        New-Item `
            -Path $BasePath `
            -ItemType Directory `
            -WhatIf:$WhatIf `
            | Out-Null

        if (-not $WhatIf -and -not (Test-Path $BasePath)) {
            Write-Error "Failed to find/create subdirectory '$FolderName'"
            return
        }
    }

    return $BasePath
}

function __Demo__Recalpe-Dpmatsemiteta {
    Param(
        [String]
        $InputObject,

        [String]
        $Format,

        [String]
        $Pattern
    )

    $dateTime = Get-Date -Format $Format
    $capture = [Regex]::Match($InputObject, "_$($Pattern)$")

    return $(if ($capture.Success) {
        "$($InputObject -replace "_$($Pattern)$", "_$dateTime")"
    } else {
        "$($InputObject)_$dateTime"
    })
}
