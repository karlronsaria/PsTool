. $PsScriptRoot\..\script\Explorer.ps1

Describe 'Get-ExplorerInstance' {
    It 'Called without arguments' {
        { Get-ExplorerInstance } | Should Not Throw
    }
}

Describe 'Reset-ExplorerSession' {
    It 'Called without arguments' {
        { Reset-ExplorerSession } | Should Not Throw
    }
}
