function What-Object {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Parameter(ParameterSetName = 'Subscript')]
        [Int]
        $Index,

        [Parameter(ParameterSetName = 'Qualifier')]
        [String]
        $Property,

        [Parameter(ParameterSetName = 'GetFirst')]
        [Switch]
        $First,

        [Parameter(
            ParameterSetName = 'Inference',
            Position = 0
        )]
        $Argument
    )

    Begin {
        $list = @()
    }

    Process {
        switch ($PsCmdlet.ParameterSetName) {
            'Qualifier' {
                return $InputObject.$Property
            }

            default {
                $list += @($InputObject)
            }
        }
    }

    End {
        if ($list.Count -gt 0) {
            switch ($PsCmdlet.ParameterSetName) {
                'Inference' {
                    switch ($Argument) {
                        { $_ -is [Int] } {
                            return $list | What-Object `
                                -Index $Argument
                        }

                        default {
                            return $list | What-Object `
                                -Property $Argument
                        }
                    }
                }

                default {
                    $i = switch ($PsCmdlet.ParameterSetName) {
                        'Subscript' { $Index }
                        'GetFirst' { 0 }
                    }

                    return $list[$i]
                }
            }
        }
    }
}

New-Alias -Name 'what' -Value 'What-Object'

