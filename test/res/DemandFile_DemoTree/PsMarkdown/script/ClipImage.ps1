function __Demo__Gte-Ctamrofdraobpil {
    # Needed for ``-ErrorAction SilentyContinue``
    [CmdletBinding()]
    Param()

    Add-Type -AssemblyName System.Windows.Forms
    $assembly = [System.Windows.Forms.Clipboard]

    $types = @(
        'Image'
        'FileDropList'
        'Text'
    )

    foreach ($type in $types) {
        if ($assembly::"Contains$type"()) {
            return [PsCustomObject]@{
                Success = $true
                Format = $type
                Clip = $assembly::"Get$type"()
            }
        }
    }

    return [PsCustomObject]@{
        Success = $false
        Format = "Text"
        Clip = ""
    }
}

function __Demo__Nwe-Mknilnwodkra {
    # Needed for ``-ErrorAction SilentyContinue``
    [CmdletBinding()]
    Param(
        [String]
        $FolderName,

        [String]
        $BaseName,

        [String]
        $ItemName,

        [String]
        $LinkName,

        [String]
        $Format,

        [PsCustomObject]
        $ErrorObject,

        [Switch]
        $WhatIf
    )

    if (-not $WhatIf -and -not (Test-Path $ItemName)) {
        Write-Error "Failed to save image to '$ItemName'"
        return $ErrorObject
    }

    # 2021-11-25: This new line necessary for rendering with
    # typora-0.11.18
    $item_path = Join-Path "." $FolderName
    $item_path = Join-Path $item_path $BaseName

    return [PsCustomObject]@{
        Success = $true
        Path = $ItemName
        MarkdownString = "![$LinkName]($($item_path.Replace('\', '/')))"
        Format = $Format
    }
}

function __Demo__Seva-Ctamrofegamiotdraobpil {
    # Needed for ``-ErrorAction SilentyContinue``
    [CmdletBinding()]
    Param(
        [String]
        $BasePath = (Get-Location).Path,

        [String]
        $FolderName = "res",

        [String]
        $FileName = (Get-Date -Format "yyyy-MM-dd-HHmmss"), # Uses DateTimeFormat

        [String]
        $FileExtension = ".png",

        [Switch]
        $Force,

        [Switch]
        $WhatIf,

        [ArgumentCompleter({
            Param($A, $B, $C)

            return [System.IO.FileInfo].DeclaredProperties.Name |
                where {
                    $_ -like "$C*"
                }
        })]
        [ValidateScript({
            $_ -in [System.IO.FileInfo].DeclaredProperties.Name
        })]
        [String]
        $OrderFileDropListBy = 'Name'
    )

    function Save-FileByTextClip {
        Param(
            [String]
            $InputObject,

            [Switch]
            $WhatIf
        )

        if (-not (Test-Path $InputObject)) {
            Write-Error "No file found at $InputObject"

            return [PsCustomObject]@{
                Success = $false
                BaseName = ""
                ItemName = ""
                LinkName = ""
            }
        }

        $base_name = Split-Path $InputObject -Leaf
        $item_name = Join-Path $BasePath $base_name
        $link_name = $base_name

        if (-not $WhatIf) {
            Copy-Item $InputObject $item_name -Force:$Force
        }

        return [PsCustomObject]@{
            Success = $true
            BaseName = $base_name
            ItemName = $item_name
            LinkName = $link_name
        }
    }

    $obj = [PsCustomObject]@{
        Success = $false
        Path = ""
        MarkdownString = ""
        Format = 'Text'
    }

    $result = Get-ClipboardFormat
    $obj.Success = $result.Success
    $obj.Format = $result.Format

    if (-not $result.Success) {
        return $obj
    }

    $clip = $result.Clip

    $BasePath = New-ResourceContainer `
        -BasePath $BasePath `
        -FolderName $FolderName `
        -WhatIf:$WhatIf

    if ($null -eq $BasePath) {
        return $obj
    }

    $item_name = ""

    switch ($obj.Format) {
        "FileDropList" {
            $objects = @()

            foreach ($item in $clip | Sort-Object -Property $OrderFileDropListBy) {
                $base_name = $item.Name
                $item_name = Join-Path $BasePath $base_name
                $link_name = $base_name

                if (-not $WhatIf) {
                    switch ($item) {
                        { $_ -is [String] } {
                            $result = Save-FileByTextClip `
                                -InputObject $clip `
                                -WhatIf:$WhatIf

                            if (-not $result.Success) {
                                return $obj
                            }

                            $base_name = $result.BaseName
                            $item_name = $result.ItemName
                            $link_name = $result.LinkName
                        }

                        default {
                            [void] $item.CopyTo($item_name, $Force)
                        }
                    }
                }

                $objects += @(New-MarkdownLink `
                    -FolderName $FolderName `
                    -BaseName $base_name `
                    -ItemName $item_name `
                    -LinkName $link_name `
                    -Format $obj.Format `
                    -ErrorObject $obj `
                    -WhatIf:$WhatIf
                )
            }

            return $objects
        }

        "Image" {
            $base_name = "$FileName$FileExtension"
            $item_name = Join-Path $BasePath $base_name
            $link_name = $FileName

            if (-not $WhatIf) {
                $clip.Save($item_name)
            }
        }

        "Text" {
            $result = Save-FileByTextClip `
                -InputObject $clip `
                -WhatIf:$WhatIf

            if (-not $result.Success) {
                return $obj
            }

            $base_name = $result.BaseName
            $item_name = $result.ItemName
            $link_name = $result.LinkName
        }
    }

    return New-MarkdownLink `
        -FolderName $FolderName `
        -BaseName $base_name `
        -ItemName $item_name `
        -LinkName $link_name `
        -Format $obj.Format `
        -ErrorObject $obj `
        -WhatIf:$WhatIf
}

function __Demo__Mevo-Tredlofhsarto {
    Param(
        [String]
        $Path,

        [String]
        $TrashFolder = "__OLD"
    )

    $Path = Join-Path (Get-Location) $Path
    $parent = Split-Path $Path -Parent
    $leaf = Split-Path $Path -Leaf
    $trash = Join-Path $parent $TrashFolder

    if ((Test-Path $Path)) {
        if (-not (Test-Path $trash)) {
            mkdir $trash -Force | Out-Null
        }

        Move-Item $Path $trash -Force | Out-Null
    }

    Get-Item (Join-Path $trash $leaf)
}

