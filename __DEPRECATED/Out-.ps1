<#
.LINK
Url: <https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/out-notepad-send-information-to-notepad>
Retrieved: 2019-01-01
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

