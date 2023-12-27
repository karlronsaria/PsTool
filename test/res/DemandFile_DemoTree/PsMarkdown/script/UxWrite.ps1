function __Demo__Gte-Umetix {
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            $setting = cat "$PsScriptRoot/../res/setting.json" |
                ConvertFrom-Json

            $setting = $setting.UxWrite
            $size = $setting.DefaultImageSize
            $ext = $setting.DefaultExtension

            return dir "$PsScriptRoot/../res/$ext/$size" -File |
                foreach {
                    [Regex]::Match($_, ".*(?=\.[^\.]+$)")
                } |
                where {
                    $_ -like "$C*"
                }
        })]
        [String]
        $Name,

        [Int]
        $Size = -1,

        [String]
        $Extension,

        [Switch]
        $UseInexactMatch
    )

    $setting = (cat "$PsScriptRoot/../res/setting.json" |
        ConvertFrom-Json).
        UxWrite

    if ($Size -lt 0) {
        $Size = $setting.DefaultImageSize
    }

    if ([String]::IsNullOrWhiteSpace($Extension)) {
        $Extension = $setting.DefaultExtension
    }

    $split = @($Name -split $setting.SplitDelimiter)
    $Name = $split[0]

    if ($split.Count -gt 1) {
        $Size = [Int]$split[1]
    }

    return dir "$PsScriptRoot/../res/$Extension/$Size" -File |
        where {
            $_.BaseName -like "$Name-$Size$(if ($UseInexactMatch) { "**" })"
        } |
        foreach {
            [PsCustomObject]@{
                FullName = $_.FullName
                MarkdownString =
                    "![$($_.Name)](./$($setting.ResourceDir)/$($_.Name))"
            }
        }
}

function __Demo__Cottrevno-Mcodetirwxud {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $File,

        [String]
        $Delimiter,

        [Int]
        $Size = -1,

        [Switch]
        $UseInexactMatch,

        [Switch]
        $Force,

        [ValidateSet('String', 'Object')]
        [String]
        $Output = 'String'
    )

    $setting = (cat "$PsScriptRoot/../res/setting.json" |
        ConvertFrom-Json).
        UxWrite

    if ([String]::IsNullOrWhiteSpace($Delimiter)) {
        $Delimiter = $setting.Delimiter
    }

    if ($Size -lt 0) {
        $Size = $setting.DefaultImageSize
    }

    $File = $File | Get-Item
    $pattern = "(?<=$Delimiter)[^$Delimiter]+(?=$Delimiter)"

    $basePath = New-ResourceDirectory `
        -BasePath $File.Directory `
        -FolderName $setting.ResourceDir

    $cat = @()
    $list = @()

    foreach ($line in (cat $File)) {
        $capture = [Regex]::Match($line, $pattern)

        while ($capture.Success) {
            $value = $capture.Value

            $items = Get-UxItem `
                -Name $value `
                -Size $Size `
                -UseInexactMatch:$UseInexactMatch

            foreach ($item in $items) {
                $name = Split-Path $item.FullName -Leaf

                Copy-Item `
                    -Path $item.FullName `
                    -Destination (Join-Path $basePath $name)
            }

            $original = "$Delimiter$value$Delimiter"
            $replace = @($items | foreach { $_.MarkdownString })

            $line = $line -replace `
                "$Delimiter$value$Delimiter", `
                ($replace -Join ' ')

            switch ($Output) {
                'String' {
                    Write-Output ""
                    Write-Output "$original ->"

                    $replace | foreach {
                        Write-Output "  $_"
                    }
                }

                'Object' {
                    $list += @([PsCustomObject]@{
                        Original = $original
                        Replace = @($replace)
                    })
                }
            }

            $capture = [Regex]::Match($line, $pattern)
        }

        $cat += @($line)
    }

    $baseName = Replace-DateTimeStamp `
        -InputObject $File.BaseName `
        -Format $setting.DateTimeFormat `
        -Pattern $setting.DateTimePattern

    $next = $File.FullName

    $prev = Join-Path `
        (Split-Path $next -Parent) `
        "$baseName$($File.Extension)"

    Rename-Item $next $prev -Force:$Force
    $cat | Out-File $next -Force:$Force

    switch ($Output) {
        'String' {
            Write-Output ""
            Write-Output "NewItemPath: $next"
            Write-Output "OldItemPath: $prev"
        }

        'Object' {
            return [PsCustomObject]@{
                Strings = $list
                NewItemPath = $next
                OldItemPath = $prev
            }
        }
    }
}

