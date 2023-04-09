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
    $path = (Get-Process -id $pid).Path
    $balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
    $balloon.BalloonTipText = ($InputObject | Out-String)
    $balloon.BalloonTipTitle = $Title

    if ($Type) {
        $balloon.BalloonTipIcon = switch ($Type) {
            "None"     { [System.Windows.Forms.ToolTipIcon]::None }
            "Error"    { [System.Windows.Forms.ToolTipIcon]::Error }
            "Info"     { [System.Windows.Forms.ToolTipIcon]::Info }
            "Warning"  { [System.Windows.Forms.ToolTipIcon]::Warning }
        }
    }

    $balloon.Visible = $true
    $balloon.ShowBalloonTip($SuggestedTimeout)
}

<#
    .LINK
        https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/out-notepad-send-information-to-notepad
#>
function Out-Notepad {
    [CmdletBinding(DefaultParameterSetName = "ByObject")]
    Param(
        [Parameter(
            ParameterSetName = "ByObject",
            ValueFromPipeline = $true)]
        [PSObject[]]
        $InputObject,

        [Parameter(
            ParameterSetName = "ByStream",
            ValueFromPipeline = $true)]
        $Stream,

        [Switch]
        $NoNewLine
    )

    Begin {
        $buf = New-Object System.Text.StringBuilder
    }

    Process {
        if ($PsCmdlet.ParameterSetName -eq "ByStream") {
            $InputObject = $Stream | Out-String
        }

        foreach ($subobject in $InputObject) {
            if ($NoNewLine) {
                $null = $buf.Append($subobject.ToString())
            } else {
                $null = $buf.AppendLine($subobject.ToString())
            }
        }
    }

    End {
        $text = $buf.ToString()
        $process = Start-Process notepad -PassThru
        [void] $process.WaitForInputIdle()

        $sig = '
            [DllImport("user32.dll", EntryPoint = "FindWindowEx")]
            public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);

            [DllImport("user32.dll")]
            public static extern int SendMessage(IntPtr hWnd, int uMsg, int wParam, string lParam);
        '

        $type = Add-Type -MemberDefinition $sig -Name APISendMessage -PassThru
        $hwnd = $process.MainWindowHandle
        [IntPtr]$child = $type::FindWindowEx($hwnd, [IntPtr]::Zero, "Edit", $null)
        $null = $type::SendMessage($child, 0x000C, 0, $text)
    }
}

<#
.ISSUE
Command
```powershell
dir \note | Out-NotepadPlusPlus
```
Expected
```
    Directory: C:\note


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----         5/24/2021   4:30 AM                banter
d-----         5/18/2021   8:08 PM                dev
d-----         5/25/2021  12:54 AM                howto
```
Actual
```
    Directory: C:\note


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----         5/24/2021   4:30 AM                banter





    Directory: C:\note


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----         5/18/2021   8:08 PM                dev





    Directory: C:\note


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----         5/25/2021  12:54 AM                howto
```
#>
function Out-NotepadPlusPlus {
    [Alias("Out-Npp")]
    [CmdletBinding(DefaultParameterSetName = "ByObject")]
    Param(
        [Parameter(
            ParameterSetName = "ByObject",
            ValueFromPipeline = $true)]
        [PSObject[]]
        $InputObject,

        [Parameter(
            ParameterSetName = "ByStream",
            ValueFromPipeline = $true)]
        $Stream,

        [Switch]
        $WhatIf
    )

    Begin {
        $buf = New-Object System.Text.StringBuilder
    }

    Process {
        if ($PsCmdlet.ParameterSetName -eq "ByStream") {
            $InputObject = $Stream | Out-String
        }

        foreach ($subobject in $InputObject) {
            if ($NoNewLine) {
                $null = $buf.Append($subobject.ToString())
            }
            else {
                $null = $buf.AppendLine($subobject.ToString())
            }
        }
    }

    End {
        $text = $buf.ToString()
        $command = "notepad++ -qt=`"$text`" -qSpeed3 -multiInst"

        if ($WhatIf) {
            "InputObject: $InputObject"
            "Command: $command"
        }
        else {
            Write-Verbose "Command: $command"
            Invoke-Expression -Command $command
        }
    }
}
