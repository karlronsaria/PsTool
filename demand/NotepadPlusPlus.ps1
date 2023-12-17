function Out-Toast {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [PsObject]
        $InputObject,

        [String]
        $Title = "Attention, $Env:USERNAME",

        [Int]
        $SuggestedTimeout = 5000,  # Milliseconds

        [ValidateSet("None", "Error", "Info", "Warning")]
        [String]
        $Type
    )

    Add-Type -AssemblyName System.Windows.Forms
    $global:balloon = New-Object System.Windows.Forms.NotifyIcon
    $path = (Get-Process -Id $PID).Path
    $balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
    $balloon.BalloonTipText = $InputObject | Out-String
    $balloon.BalloonTipTitle = $Title

    if ($Type) {
        $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::$Type
    }

    $balloon.Visible = $true
    $balloon.ShowBalloonTip($SuggestedTimeout)
}

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
