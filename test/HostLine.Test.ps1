#Requires -Module Pester

Describe 'Clear-HostLine' {
    BeforeAll {
        . $PsScriptRoot\..\script\HostLine.ps1
    }

    Context 'Called' {
        It 'Without arguments' {
            Write-Host 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
            { Clear-HostLine } | Should Not Throw
        }
    }
}

