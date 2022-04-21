function Start-Timer {
    Param(
        [Int]
        $Minutes = 0,

        [Int]
        $Seconds = 0,

        [Switch]
        $Bell
    )

    $Seconds += 60 * $Minutes

    while ($Seconds -gt 0) {
        Write-Host "`rSeconds left: $Seconds                " -NoNewLine
        Start-Sleep -Seconds 1
        $Seconds--
    }

    Write-Host "`rSeconds left: $Seconds                " -NoNewLine

    if ($Bell) {
        Write-Output "`a"
    }
}

