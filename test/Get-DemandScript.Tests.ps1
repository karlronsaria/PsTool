#Requres -Module Pester

Describe 'Get-DemandScript' {
    BeforeAll {
        iex "$PsScriptRoot\..\Get-Scripts.ps1" | foreach { . $_ }

        $stuff = gc "$PsScriptRoot\res\Get-DemandScript.Mock.json" |
            ConvertFrom-Json `
            -AsHashtable
    }

    Context "Calling function" {
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
                        ConvertTo-Json `
                            -Depth $stuff.MaxDepth `
                            -WarningAction SilentlyContinue |
                        ConvertFrom-Json -AsHashtable
                    }

                    default {
                        $_
                    }
                }

                $actual | Should Not Be $null

                # If not converted to a list, will call ``[Hashtable]``'s
                # ``Count`` instead
                @($actual).Count | Should Be $Value.Count

                diff ($actual) ($Value) | Should Be $null
            }
        }
    }
}
