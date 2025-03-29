<#
.LINK
Url: <https://superuser.com/questions/1623573/powershell-how-to-play-different-system-sounds>
Retrieved: 2023-09-22
#>
function Start-Timer {
    Param(
        [Int]
        $Minutes = 0,

        [Int]
        $Seconds = 0,

        [Switch]
        $Bell,

        [Switch]
        $InConsole
    )

    $Seconds += 60 * $Minutes
    $blank = " " * 20

    $action = if ($InConsole) {
        {
            Param([Int] $Total, [Int] $Remaining, [String] $Spinner)

            Write-Host `
                "`rSeconds left: [$Spinner] $Remaining$blank" -NoNewLine
        }
    }
    else {
        {
            Param([Int] $Total, [Int] $Remaining, [String] $Spinner)

            Write-Progress `
                -Activity "Countdown" `
                -Status "`rSeconds left: [$Spinner] $Remaining$blank" `
                -SecondsRemaining $Remaining `
                -PercentComplete `
                    ([Math]::Min(100, 100 * (($Total - $Remaining) / $Total) + 1))
        }
    }

    $total = $Seconds

    while ($Seconds -gt 0) {
        & $action -Total $total -Remaining $Seconds -Spinner "-"
        Start-Sleep -Milliseconds 250
        & $action -Total $total -Remaining $Seconds -Spinner "\"
        Start-Sleep -Milliseconds 250
        & $action -Total $total -Remaining $Seconds -Spinner "|"
        Start-Sleep -Milliseconds 250
        & $action -Total $total -Remaining $Seconds -Spinner "/"
        Start-Sleep -Milliseconds 250
        $Seconds--
    }

    if (-not $InConsole) {
        Write-Progress `
            -Activity "Countdown" `
            -Status "`rSeconds left: [-] $Seconds$blank" `
            -PercentComplete 100 `
            -Complete
    }
    else {
        Write-Host "`rSeconds left: $Seconds$blank" -NoNewLine
    }

    if ($Bell) {
        # (karlr 2023-09-22-200523) The bell escape sequence does not seem
        # to work, at least not as well as I want it to
        #
        # link
        # - url: <https://superuser.com/questions/1623573/powershell-how-to-play-different-system-sounds>
        [System.Console]::Beep(1000,300)

        # # old (karlr 2023-09-22-200426)
        # Write-Output "`a"
    }
}

