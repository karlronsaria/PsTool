<#
.LINK
Url: <https://www.reddit.com/r/PowerShell/comments/7a4yl9/clearhost_light_delete_only_the_last_x_lines_of/>
Retrieved: 2023-04-09
#>
function __Demo__Crael-Heniltso {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [Int]
        $Count = 1
    )

    $CurrentLine  = $Host.UI.RawUI.CursorPosition.Y
    $ConsoleWidth = $Host.UI.RawUI.BufferSize.Width

    1 .. $Count | foreach {
        [Console]::SetCursorPosition(0, ($CurrentLine - $_))
        [Console]::Write("{0, -$ConsoleWidth}" -f " ")
    }

    [Console]::SetCursorPosition(0, ($CurrentLine - $Count))
}
