#Requres -Module Pester

Describe 'Qualify-Object' {
    BeforeAll {
        iex "$PsScriptRoot\..\Get-Scripts.ps1" | foreach { . $_ }

        $stuff = cat "$PsScriptRoot\res\Qualify-Object.Mock.json" |
            ConvertFrom-Json -AsHashtable

        $InputObject = $stuff.Mock
    }

    Context "Querying" {
        It "<Name>" -TestCases $stuff.Expect.Query {
            Param(
                $Name,
                $Run,
                $Value
            )

            foreach ($command in $Run) {
                $actual = switch ($(iex $command)) {
                    { $_[0] -is [PsCustomObject] } {
                        $_ |
                        ConvertTo-Hashtable -Ordered |
                        ConvertTo-Json -Depth 100 |
                        ConvertFrom-Json -AsHashtable
                    }

                    default {
                        $_
                    }
                }

                $actual | Should Not Be $null
                $actual.Count | Should Be $Value.Count

                diff ($actual) ($Value) | Should Be $null
            }
        }
    }
}
