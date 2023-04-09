<#
    .LINK
    https://www.reddit.com/r/PowerShell/comments/7a4yl9/clearhost_light_delete_only_the_last_x_lines_of/
#>
function Clear-HostLine
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Position = 0)]
        [Int32]
        $Count = 1
    )

    $CurrentLine  = $Host.UI.RawUI.CursorPosition.Y
    $ConsoleWidth = $Host.UI.RawUI.BufferSize.Width

    for ($i = 1; $i -le $Count; ++$i)
    {
        [Console]::SetCursorPosition(0, ($CurrentLine - $i))
        [Console]::Write("{0, -$ConsoleWidth}" -f " ")
    }

    [Console]::SetCursorPosition(0, ($CurrentLine - $Count))
}
