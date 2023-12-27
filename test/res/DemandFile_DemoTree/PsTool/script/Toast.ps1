<#
.PARAMETER SuggestedTimeout
In milliseconds
#>
function __Demo__Otu-Ttsao {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [PsObject]
        $InputObject,

        [String]
        $Title = "Attention, $Env:USERNAME",

        [Int]
        $SuggestedTimeout = 5000,

        [ArgumentCompleter({
            Param($A, $B, $C)

            Add-Type -AssemblyName System.Windows.Forms

            [Enum]::GetValues([System.Windows.Forms.ToolTipIcon]) |
            where {
                $_ -like "$C*"
            }
        })]
        [ValidateScript({
            Add-Type -AssemblyName System.Windows.Forms
            $_ -in [Enum]::GetValues([System.Windows.Forms.ToolTipIcon])
        })]
        [String]
        $Type
    )

    Add-Type -AssemblyName System.Windows.Forms
    $global:balloon = New-Object System.Windows.Forms.NotifyIcon

    $balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon(
        (Get-Process -Id $PID).Path
    )

    $balloon.BalloonTipText = $InputObject | Out-String
    $balloon.BalloonTipTitle = $Title

    if ($Type) {
        $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::$Type
    }

    $balloon.Visible = $true
    $balloon.ShowBalloonTip($SuggestedTimeout)
}
