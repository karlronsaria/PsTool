<#
Tags: ole, word, msword, docx
#>

<#
.DESCRIPTION
Requires OpenMcdf.dll, which can be installed from NuGet using the command:

```powershell
Install-Package OpenMcdf
```

Find the *.dll file and place it in the bin/ folder of this module
#>
function Out-OleBinaryStream {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $File,

        [String]
        $Destination
    )

    Begin {
        $dllPath = "$PsScriptRoot\..\bin\OpenMcdf.dll"
        $continue = Test-Path $dllPath

        if (-not $continue) {
            "This command requires OpenMcdf.dll, which can be installed from NuGet using the command:"
            ""
            "  Install-Package OpenMcdf"
            ""
            "Find the *.dll file and place it in the bin/ folder of this module"

            return
        }

        Add-Type -Path "$PsScriptRoot\..\bin\OpenMcdf.dll"

        if (-not $Destination) {
            $Destination = Get-Location
        }

        if (-not (Test-Path $Destination)) {
            mkdir $Destination
        }

        $activity = "Reading OLE Binary"

        Write-Progress `
            -Id 1 `
            -Activity $activity `
            -PercentComplete 0

        $count = 0
        $files = @()
    }

    Process {
        if (-not $continue) {
            return
        }

        $files += @($File)
        $count++
    }

    End {
        if (-not $continue) {
            return
        }

        $index = 0

        foreach ($item in $files) {
            $item = Get-Item $item
            $com = New-Object OpenMcdf.CompoundFile -ArgumentList $item
            $store = $com.RootStorage

            Set-Variable `
                -Scope Global `
                -Name list `
                -Value @()

            $store.VisitEntries({
                param($item)

                $list = Get-Variable `
                    -Scope Global `
                    -Name list

                Set-Variable `
                    -Scope Global `
                    -Name list `
                    -Value (@($list.Value) + @($item))
            }, $true)

            $ext = 'txt'
            $compObj = $list | where { $_.Name -eq 'CompObj' }

            if ($null -ne $compObj) {
                $title = [System.Text.Encoding]::ASCII.GetString($compObj.GetData())

                if ($title -match "Picture \(Device Independent Bitmap\)") {
                    $ext = 'bmp'
                }
            }

            $name = "$($item.BaseName).$ext"
            $path = Join-Path $Destination $name
            $index++

            Write-Progress `
                -Id 1 `
                -Activity $activity `
                -Status "Setting content for $name" `
                -PercentComplete (100 * $index / $count)

            Set-Content `
                -Path $path `
                -Value $store.GetStream("CONTENTS").GetData() `
                -AsByteStream

            $path
        }

        Write-Progress `
            -Id 1 `
            -Activity $activity `
            -Complete
    }
}

<#
.DESCRIPTION
Requires ImageMagick
#>
function New-MarkdownImageGallery {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [String]
        $Destination,

        [String]
        $GalleryFile = 'readme.md',

        [String]
        $ResourceDir = 'res',

        [ValidateScript({ $_ -gt 0 })]
        [Int]
        $LineSpacing = 2
    )

    Begin {
        if (-not $Destination) {
            $Destination = Get-Location
        }

        $resPath = Join-Path $Destination $ResourceDir

        if (-not (Test-Path $resPath)) {
            mkdir $resPath
        }

        $dtFormat = Get-Item "$PsScriptRoot/../res/setting.json" |
            Get-Content |
            ConvertFrom-Json |
            foreach { $_.DateTimeFormat }

        $list = @()
        $count = 0
        $activity = "New Markdown Gallery"

        Write-Progress `
            -Id 1 `
            -Activity $activity `
            -PercentComplete 0
    }

    Process {
        $list += @(Get-Item $InputObject)
        $count++
    }

    End {
        $index = 0
        $lines = @()

        foreach ($item in $list) {
            $capture = [regex]::Match($item.BaseName, "(?<word>\D+)(?<num>\d+)")
            $word = $capture.Groups['word'].Value
            $num = $capture.Groups['num'].Value

            # # (karlr 2025_01_13): resource files need to have unique identifiers
            # $newName = "$word$("{0:d2}" -f [int]$num).png"

            # # (karlr 2025_01_13): I decided I'll just add both
            $newName = "$($word)$("{0:d2}" -f [int]$num)_$(Get-Date -f $dtFormat).png"
            $newPath = "$resPath/$($newName)"

            Write-Progress `
                -Id 1 `
                -Activity $activity `
                -Status "Converting $($item.BaseName)" `
                -PercentComplete (100 * $index / $count)

            magick $item.FullName $newPath
            $newItem = Get-Item $newPath
            $index++

            if (-not (Test-Path $newItem)) {
                "ImageMagick failed for item $($item.Name)"
                continue
            }

            $lines += @("![$newName](./$ResourceDir/$newName)")

            for ($i = 1; $i -lt ($LineSpacing); $i++) {
                $lines += @("")
            }
        }

        Write-Progress `
            -Id 1 `
            -Activity $activity `
            -Complete

        $lines |
        Out-FileUnix -FilePath (Join-Path $Destination $GalleryFile)
    }
}

