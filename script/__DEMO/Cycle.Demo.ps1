function Show-ScrollingGreenTextBar {
    Param(
        [String]
        $Line
    )

    0 .. ($Line.Length - 1) |
    foreach -Begin {
        $myLine = $Line
    } -Process {
        $myLine
        $myLine = "$($myLine.Substring(1))$($myLine[0])"
    } |
    cycle |
    foreach {
        $toGreen = Write-Color `
            -InputObject $_ `
            -Red 0 `
            -Green 255 `
            -Blue 0 `
            -ApplyTo 'Foreground'

        Write-Progress `
            -Activity "Loading" `
            -Status $toGreen `
            -PercentComplete 0

        Start-Sleep `
            -Milliseconds 200
    }
}

