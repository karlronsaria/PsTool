function ConvertFrom-MsExcel {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [System.IO.FileSystemInfo]
        $File
    )

    $setting = cat "$PsScriptRoot/../res/convert.setting.json" `
        | ConvertFrom-Json

    $excel = New-Object -ComObject Excel.Application
    $workbook = $excel.Workbooks.Open($File)
    $list = @()

    foreach ($sheetInfo in $workbook.Sheets) {
        $rows = @()
        $tableRows = $sheetInfo.UsedRange.Rows
        $header = $tableRows[1].Formula2
        $count = $header.Count
        $rowNo = 2
        $gapRows = 0

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
                Name = $sheetInfo.Name
                Rows = $rows
            } `
        )
    }

    return [PsCustomObject]@{
        FileName = $File.Name
        Sheets = $list
    }
}
