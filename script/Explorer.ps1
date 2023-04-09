<#
    .LINK
        https://stackoverflow.com/questions/58783530/powershell-script-to-list-all-open-explorer-windows

    .LINK
        https://stackoverflow.com/users/45375/mklement0
#>
function Get-ExplorerInstance {
    [CmdletBinding()]
    Param(
        [String]
        $Name,

        [String]
        $Path,

        [ValidateSet(
            'File folder',
            'System Folder',
            'CD Drive',
            'USB Drive'
        )]
        [String]
        $Type
    )

    $windows = (New-Object -ComObject 'Shell.Application').Windows()
    $windows = $windows | foreach { $_.Document.Folder.Self }
    $windows = $windows | select Name, Path, Type, ModifyDate

    if ($Name) {
        $windows = $windows | where { $_.Name -like $Name }
    }

    if ($Path) {
        $windows = $windows | where { $_.Path -like $Path }
    }

    if ($Type) {
        $windows = $windows | where { $_.Path -like $Type }
    }

    return $windows
}

function Reset-ExplorerSession {
    [CmdletBinding(DefaultParameterSetName = "ReopenItems")]
    Param(
        [Parameter(ParameterSetName = "ReopenItems")]
        [ValidateSet("Normal", "Hidden", "Minimized", "Maximized")]
        $WindowStyle = "Normal",

        [Parameter(ParameterSetName = "ReopenItems")]
        [Switch]
        $PassThru,

        [Parameter(ParameterSetName = "NoReopenItems")]
        [Switch]
        $NoReopen
    )

    $items = Get-ExplorerInstance
    taskkill /f /im explorer.exe
    Start-Process -FilePath explorer.exe

    if (-not $NoReopen) {
        $items | % {
            Start-Process `
                -FilePath explorer.exe `
                -ArgumentList $_ `
                -WindowStyle:$WindowStyle `
                -PassThru:$PassThru
        }
    }
}
