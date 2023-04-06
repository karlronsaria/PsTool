function ConvertFrom-MsExcel {
    [CmdletBinding(DefaultParameterSetName = 'AllSheets')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [System.IO.FileSystemInfo]
        $File,

        [Parameter(ParameterSetName = 'SheetsBySubstring')]
        [String]
        $Like,

        [Parameter(ParameterSetName = 'SheetsByPattern')]
        [String]
        $Matching,

        [Parameter(ParameterSetName = 'SheetsByIndex')]
        [Int]
        $Index,

        [Parameter(ParameterSetName = 'SheetsByIndex')]
        [Nullable[Int]]
        $EndIndex
    )

    $setting = cat "$PsScriptRoot/../res/msexcel.setting.json" `
        | ConvertFrom-Json

    $excel = New-Object -ComObject Excel.Application
    $workbook = $excel.Workbooks.Open($File)

    $sheets = switch ($PsCmdlet.ParameterSetName) {
        'SheetsBySubstring' {
            $workbook.Sheets | where {
                $_.Name -like $Like
            }
        }

        'SheetsByPattern' {
            $workbook.Sheets | where {
                $_.Name -match $Matching
            }
        }

        'SheetsByIndex' {
            if ($null -eq $Index) {
                @()
            } elseif ($null -eq $EndIndex) {
                $workbook.Sheets[$Index]
            } else {
                $workbook.Sheets[$Index .. $EndIndex]
            }
        }

        default {
            $workbook.Sheets
        }
    }

    $sheets = @($sheets)
    $list = @()
    $sheetIndex = 0

    foreach ($sheetInfo in $sheets) {
        $caption = $sheetInfo.Name
        $rows = @()
        $tableRows = $sheetInfo.UsedRange.Rows
        $header = $tableRows[1].Formula2
        $count = $header.Count
        $rowNo = 2
        $gapRows = 0

        $outerLoopProgressParams = @{
            Activity = "Sheet: $caption"
            PercentComplete = $sheetIndex * 100 / $sheets.Count
        }

        Write-Progress @outerLoopProgressParams
        $sheetIndex++

        while ($rowNo -le $tableRows.Count `
            -and $gapRows -le $setting.GapLength)
        {
            $obj = [PsCustomObject]@{}
            $colNo = 1
            $empty = $true

            while ($colNo -le $count) {
                $name = "$($header[1, $colNo])"

                if ([String]::IsNullOrWhiteSpace($name)) {
                    $colNo = $colNo + 1
                    continue
                }

                $value = $tableRows[$rowNo].Formula2[1, $colNo]

                $empty = $empty -and ( `
                    [String]::IsNullOrEmpty("$value") `
                    -or "$value".ToLower() -in $setting.EmptyPatterns `
                )

                $obj | Add-Member `
                    -MemberType NoteProperty `
                    -Name $name `
                    -Value $value

                $colNo = $colNo + 1
            }

            if ($empty) {
                $gapRows++
            }
            else {
                $rows += @($obj)
                $gapRows = 0
            }

            $rowNo = $rowNo + 1
        }

        $list += @(
            [PsCustomObject]@{
                Name = $caption
                Rows = $rows
            } `
        )
    }

    $workbook.Close()
    $excel.Quit()

    return [PsCustomObject]@{
        FileName = $File.Name
        Sheets = $list
    }
}

function ForEach-MsExcelWorksheet {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [System.IO.FileSystemInfo]
        $File,

        [ScriptBlock]
        $Do,

        [String]
        $Destination
    )

    $setting = cat "$PsScriptRoot/../res/msexcel.setting.json" `
        | ConvertFrom-Json

    $excel = New-Object -ComObject Excel.Application
    $workbook = $excel.Workbooks.Open($File)
    $sheetIndex = 0

    foreach ($sheet in $workbook.Sheets) {
        $caption = $sheet.Name

        $outerLoopProgressParams = @{
            Activity = "Sheet: $caption"
            PercentComplete = $sheetIndex * 100 / $workbook.Sheets.Count
        }

        Write-Progress @outerLoopProgressParams
        $sheetIndex++
        $sheet | foreach $Do
    }

    if (-not $Destination -or $Destination -eq $File.Name) {
        $Destination = $File.Name -Replace `
            "(?=\.[^.]+$)", `
            "_$(Get-Date -f $setting.DateTimeFormat)"
    }

    $Destination = Join-Path (Get-Location).Path $Destination
    $workbook.SaveAs($Destination)
    $workbook.Save()
    $workbook.Close()
    $excel.Quit()
}

