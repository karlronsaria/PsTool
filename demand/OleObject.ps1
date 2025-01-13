<#
Tags: ole, word, msword
#>

<#
.DESCRIPTION
Requires OpenMcdf.dll, which can be installed from NuGet using the command:

```powershell
Install-Package OpenMcdf
```

Find the *.dll file and place it in the bin/ folder of this module
#>
Out-OleBinaryStream {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $File,

        [String]
        $Destination
    )

    Begin {
        $dllPath = "$PsScriptRoot:..\bin\OpenMcdf.dll"
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

        $activity = "Reading OLE Binary"

        Write-Progress `
            -Id 1 `
            -Activity $activity

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
        }

        Write-Progress `
            -Id 1 `
            -Activity $activity `
            -Complete
    }
}

