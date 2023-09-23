<#
.LINK
Url: https://superuser.com/questions/1623573/powershell-how-to-play-different-system-sounds
Retrieved: 2023_09_22
#>
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
    $blank = " " * 20

    while ($Seconds -gt 0) {
        Write-Host "`rSeconds left: $Seconds$blank" -NoNewLine
        Start-Sleep -Seconds 1
        $Seconds--
    }

    Write-Host "`rSeconds left: $Seconds$blank" -NoNewLine

    if ($Bell) {
        # (karlr 2023_09_22_200523) The bell escape sequence does not seem
        # to work, at least not as well as I want it to
        #
        # link
        # - url: https://superuser.com/questions/1623573/powershell-how-to-play-different-system-sounds
        [System.Console]::Beep(1000,300)

        # # old (karlr 2023_09_22_200426)
        # Write-Output "`a"
    }
}

