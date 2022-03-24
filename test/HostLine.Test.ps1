. $PsScriptRoot\..\script\HostLine.ps1

Describe 'Clear-HostLine' {
    It 'Called without arguments' {
        Write-Host 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        { Clear-HostLine } | Should Not Throw
    }
}

