. $PsScriptRoot\..\demand\ProxyFunction.ps1

Describe 'Get-ProxyFunction' {
    It 'Called without arguments' {
        Get-ProxyFunction | Should Be $null
    }

    It 'Called with an argument' {
        $result = Get-ProxyFunction `
            -Name 'Get-ChildItem'

        $result | Should Not Be $null
    }
}
