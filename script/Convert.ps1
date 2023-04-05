function ConvertFrom-MsExcel {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [System.IO.FileSystemInfo]
        $File
    )

    $excel = New-Object -ComObject Excel.Application
    $workbook = $excel.Workbooks.Open($File)
    $list = @()

    foreach ($sheetInfo in $workbook.Sheets) {
        $rows = @()
        $tableRows = $sheetInfo.UsedRange.Rows
        $header = $tableRows[1].Formula2
        $count = $header.Count
        $rowNo = 2

        while ($rowNo -le $tableRows.Count) {
            $obj = [Ordered]@{}
            $colNo = 1

            while ($colNo -le $count) {
                $obj[$header[1, $colNo]] =
                    $tableRows[$rowNo].Formula2[1, $colNo]
                $colNo = $colNo + 1
            }

            $rowNo = $rowNo + 1
            $rows += @([PsCustomObject]$obj)
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
