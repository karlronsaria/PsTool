. $PsScriptRoot\..\script\Other.ps1

Describe 'Get-ShortName' {
    It 'Called without arguments' {
        Get-ShortName | Should Be $null
    }

    $resPath = "$PsScriptRoot\res"

    It  -Name "Given valid Path '<Path>', it returns '<Expected>'" `
        -TestCases @(
            @{ Path = "$resPath\File.txt";
                Expected = 'File.txt' }
            @{ Path = "$resPath\FileWithLongName.txt";
                Expected = 'FILEWI~1.TXT' }
            @{ Path = "$resPath\FileWithVeryLongName.txt";
                Expected = 'FILEWI~2.TXT' }
        ) `
        -Test {
            Param ($Path, $Expected)
            $Path | Get-ShortName | Should Be $Expected
        }
}

Describe 'ConvertTo-Hashtable' {
    It 'Called without arguments' {
        ConvertTo-Hashtable | Should Be $null
    }

    $testTable = @{
        Lorem = "ipsum"
        Dolor = "sit amet"
        Consectetur = "adipiscing elit sed do"
        Eiusmod = "tempor indicindut ut labore et"
        Dolore = "magna aliqua"
    }

    It  -Name "Given <Typename>, returns Hashtable" `
        -TestCases @(
            @{ Object = [PsCustomObject]$testTable;
                Expected = $testTable;
                Typename = 'PsCustomObject' },
            @{ Object = ([PsCustomObject]$testTable).PsObject;
                Expected = $testTable;
                Typename = 'PsObject' }
        ) `
        -Test {
            Param ($Object, [Hashtable]$Expected)
            $result = $testTable | ConvertTo-Hashtable
            Compare-Object ($result) ($Expected) | Should Be $null
        }
}

