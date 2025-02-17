function Out-NotepadPlusPlus {
    [Alias("Out-Npp")]
    [CmdletBinding(DefaultParameterSetName = "ByObject")]
    Param(
        [Parameter(
            ParameterSetName = "ByObject",
            ValueFromPipeline = $true
        )]
        [Object[]]
        $InputObject,

        [Parameter(
            ParameterSetName = "ByStream",
            ValueFromPipeline = $true
        )]
        $Stream,

        [Switch]
        $WhatIf
    )

    Begin {
        $list = @()
    }

    Process {
        if ($PsCmdlet.ParameterSetName -eq "ByStream") {
            $InputObject = $Stream | Out-String
        }

        foreach ($item in $InputObject) {
            $list += @($list)
        }
    }

    End {
        $command =
            "notepad++ -qt=`"$($list | Out-String)`" -qSpeed3 -multiInst"

        if ($WhatIf) {
            return [PsCustomObject]@{
                InputObject = $list
                Command = $command
            }
        }

        Write-Verbose "Command: $command"
        Invoke-Expression -Command $command
    }
}
