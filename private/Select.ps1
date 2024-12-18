function Compare-SetFromList {
    [CmdletBinding(DefaultParameterSetName = 'UsingStrings')]
    Param(
        [Parameter(
            ValueFromPipeline = $true,
            Position = 0
        )]
        $ReferenceObject = @(),

        [Parameter(
            Position = 1
        )]
        [String[]]
        $DifferenceObject = @(),

        [Parameter(
            ParameterSetName = 'UsingObjects'
        )]
        [String]
        $GroupBy,

        [Parameter(
            ParameterSetName = 'UsingObjects'
        )]
        [String[]]
        $SelectBy,

        [ValidateSet('Or', 'And')]
        [String]
        $Mode = 'Or',

        $AdditionalObject = @(),

        [Switch]
        $CaseSensitive
    )

    Begin {
        $list = $()
    }

    Process {
        $list += @($ReferenceObject)
    }

    End {
        if ($list.Count -eq 0) {
            return @()
        }

        $listOfObjects =
            $PsCmdlet.ParameterSetName -eq 'UsingObjects' -or
            $list[0] -is [PsCustomObject]

        if ($listOfObjects) {
            $list = $list | group $GroupBy
        }

        return $(
            $list |
            where {
                if (@($DifferenceObject).Count -eq 0) {
                    $true
                }
                else {
                    $ref = if ($listOfObjects) {
                        foreach ($name in @($SelectBy)) {
                            $_.Group.$name
                        }
                    }
                    else {
                        $_
                    }

                    $ref = if ($CaseSensitive) {
                        $ref | select -Unique
                    }
                    else {
                        switch($PsVersionTable.PsVersion.Major) {
                            7 {
                                $ref | select -Unique -CaseInsensitive
                            }

                            default {
                                $ref | foreach { $_.ToLower() } | select -Unique
                            }
                        }
                    }

                    $ref = @($ref) + @($AdditionalObject)
                    $diff = Compare-Object ($ref) ($DifferenceObject)

                    $null -eq $diff -or
                        ($Mode -eq 'Or' -or
                        $diff.SideIndicator -notcontains '=>') -and
                        $diff.Count -lt `
                        (@($ref).Count + @($DifferenceObject).Count)
                }
            } |
            foreach {
                if ($listOfObjects) {
                    $_.Group
                }
                else {
                    $_
                }
            }
        )
    }
}

