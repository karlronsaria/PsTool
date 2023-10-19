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

    Write-Progress -Activity "Sheets" -Complete

    $workbook.Close()
    $excel.Quit()
    [void] [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)

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

    Begin {
        $setting = cat "$PsScriptRoot/../res/msexcel.setting.json" `
            | ConvertFrom-Json
    }

    Process {
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

        Write-Progress -Activity "Sheets" -Complete

        if (-not $Destination -or $Destination -eq $File.Name) {
            $Destination = $File.Name -Replace `
                "(?=\.[^.]+$)", `
                "_$(Get-Date -f $setting.DateTimeFormat)"

            $Destination = Join-Path (Get-Location).Path $Destination
        }

        $workbook.SaveAs($Destination)
        $workbook.Save()
        $workbook.Close()
        $excel.Quit()

        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) `
            | Out-Null

        return Get-Item $Destination
    }
}

function New-MsExcelMonthBook {
    Param(
        [ValidateRange(1, 12)]
        [Nullable[Int]]
        $Month,

        [ValidateRange(1970, 9999)]
        [Nullable[Int]]
        $Year,

        [String[]]
        $ColumnHeadings,

        [String]
        $SheetNameDateFormat,

        [String]
        $Destination
    )

    $setting = cat "$PsScriptRoot/../res/msexcel.setting.json" `
        | ConvertFrom-Json

    $now = Get-Date

    if ($null -eq $Year) {
        $Year = $now.Year
    }

    if ($null -eq $Month) {
        $Month = $now.Month
    }

    if (-not $SheetNameDateFormat) {
        $SheetNameDateFormat = $setting.SheetNameDateFormat
    }

    if (-not $Destination) {
        $date = Get-Date `
            -Year $Year `
            -Month $Month

        $Destination = $date.ToString($setting.MonthTableDateFormat) `
            + "_$((Get-Date).ToString("ddHHmmss"))" `
            + $setting.ExcelExtension

        $Destination = Join-Path (Get-Location).Path $Destination
    }

    $excel = New-Object -ComObject Excel.Application
    $workbook = $excel.Workbooks.Add()

    foreach ($day in 2 .. [DateTime]::DaysInMonth($Year, $Month)) {
        [void] $workbook.Worksheets.Add()
    }

    $day = 1

    foreach ($sheet in $workbook.Worksheets) {
        $date = Get-Date `
            -Year $Year `
            -Month $Month `
            -Day $day

        $sheet.Name = $date.ToString($SheetNameDateFormat)
        [void] $sheet.Activate()
        $colNo = 1

        foreach ($item in $ColumnHeadings) {
            $sheet.Cells(1, $colNo).Value2 = $item
            $colNo = $colNo + 1
        }

        $day = $day + 1
    }

    [void] $workbook.Worksheets[1].Activate()
    $workbook.SaveAs($Destination)
    $workbook.Save()
    $workbook.Close()
    $excel.Quit()
    [void] [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)
    return Get-Item $Destination
}
