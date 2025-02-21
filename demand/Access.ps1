<#
.DESCRIPTION
Tags: access, accessibility
#>

Import-DemandModule closure

Add-Type @"
    using System;
    using System.Text;
    using System.Runtime.InteropServices;

    public class WinAPI {
        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

        [DllImport("user32.dll")]
        public static extern bool IsWindowVisible(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();

        public static string GetWindowTitle(IntPtr hWnd) {
            StringBuilder sb = new StringBuilder(1024);
            GetWindowText(hWnd, sb, sb.Capacity);
            return sb.ToString();
        }

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool PostMessage(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam);

        public static bool CloseWindow(IntPtr hWnd) {
            const int WM_CLOSE = 0x0010;
            return PostMessage(hWnd, WM_CLOSE, 0, 0);
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct RECT {
            public int Left;
            public int Top;
            public int Right;
            public int Bottom;
        }

        [DllImport("dwmapi")]
        static extern int DwmGetWindowAttribute(
            IntPtr hwnd,
            Int32 dwAttribute,
            out RECT pvAttribute,
            Int32 cbAttribute
        );

        public static int[] GetWindowLogicalRectangle(IntPtr hWnd) {
            RECT rect;
            int attr = 9; // DWMA_EXTENDED_FRAME_BOUNDS
            int S_OK = 0;

            if (S_OK != DwmGetWindowAttribute(hWnd, attr, out rect, Marshal.SizeOf(typeof(RECT))))
                return new int[] { -1, -1, -1, -1 }; // Error case

            int width = rect.Right - rect.Left;
            int height = rect.Bottom - rect.Top;
            return new int[] { rect.Left, rect.Top, width, height };
        }
    }
"@

function Get-OpenWindow {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            $windows = Get-OpenWindow

            Set-Variable `
                -Name MyTest `
                -Scope Global `
                -Value $windows

            return $windows.Caption | where {
                "`"$_`"" -like "`"$C*`""
            } | foreach {
                "`"$_`""
            } | foreach {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
        })]
        [Parameter(
            ParameterSetName = 'ByCaption',
            Position = 0
        )]
        [String]
        $Caption,

        [ArgumentCompleter({
            Param($A, $B, $C)

            $windows = Get-OpenWindow

            Set-Variable `
                -Name MyTest `
                -Scope Global `
                -Value $windows

            return $(
                $windows.HandleId |
                foreach {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                }
            )
        })]
        [Parameter(ParameterSetName = 'ByHandleId')]
        [String]
        $HandleId
    )

    switch ($PsCmdlet.ParameterSetName) {
        'ByCaption' {
            return Get-OpenWindow | where { $_.Caption -eq $Caption }
        }

        'ByHandleId' {
            return Get-OpenWindow | where { $_.HandleId -eq $HandleId }
        }
    }

    $listName = '_' + (
        "$((Get-Item ($PsScriptRoot)).FullName)$('_' * 8)".GetEnumerator() |
            Sort-Object { Get-Random } |
            where { $_ -match "\w" }
    ) -join ''

    Set-Variable `
        -Scope Global `
        -Name $listName `
        -Value @()

    $closure = New-Closure `
        -Parameters $listName `
        -ScriptBlock {
            Param($hwnd, $lparam)

            $list = Get-Variable `
              -Name $Parameters `
              -Scope Global

            Set-Variable `
              -Scope Global `
              -Name $Parameters `
              -Value ($list.Value + @(
                [PsCustomObject]@{
                  HandleId = $hwnd
                  Caption = [WinAPI]::GetWindowTitle($hwnd)
                  Visible = [WinAPI]::IsWindowVisible($hwnd)
                }
              ))

            return $true
        }

    [WinAPI]::EnumWindows($closure, [IntPtr]::Zero) | Out-Null

    Get-Variable `
        -Scope Global `
        -Name $listName |
        foreach {
            $_.Value
        } |
        where {
            $_.Visible -and $_.Caption.Trim()
        }

    Remove-Variable `
        -Scope Global `
        -Name $listName
}

function Set-ForegroundOpenWindow {
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            $windows = Get-OpenWindow

            Set-Variable `
                -Name MyTest `
                -Scope Global `
                -Value $windows

            return $windows.Caption | where {
                "`"$_`"" -like "`"$C*`""
            } | foreach {
                "`"$_`""
            } | foreach {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
        })]
        [String]
        $Caption
    )

    $closure = New-Closure `
        -Parameters $Caption `
        -ScriptBlock {
            Param($hWnd, $lParam)

            if ([WinAPI]::GetWindowTitle($hWnd).Trim() -eq $Parameters) {
                [WinAPI]::SetForegroundWindow($hWnd)
                return $false
            }

            return $true
        }

    if (-not $Caption) {
        $windows = Get-OpenWindow
        Import-Module PsQuickform

        $menu = [pscustomobject]@{
            Preferences = [pscustomobject]@{
                Caption = 'Focus Window'
            }
            MenuSpecs = @(
                [pscustomobject]@{
                    Name = 'Caption'
                    Type = 'Enum'
                    Mandatory = $true
                    Symbols =
                        $windows |
                        foreach -Begin {
                            $c = 0
                        } -Process {
                            [pscustomobject]@{
                                Name = $c
                                Text = $_.Caption
                            }

                            $c = $c + 1
                        }
                }
            )
        }

        $result = $menu | Show-QformMenu

        if (-not $result.Confirm) {
            return
        }

        $window = $windows[$result.MenuAnswers.Caption]

        $closure = New-Closure `
            -Parameters $window.HandleId `
            -ScriptBlock {
                Param($hWnd, $lParam)

                if ([string]$hWnd -eq $Parameters) {
                    [WinAPI]::SetForegroundWindow($hWnd)
                    return $false
                }

                return $true
            }
    }

    [WinAPI]::EnumWindows([WinAPI+EnumWindowsProc] $closure, [IntPtr]::Zero) | Out-Null
}

function Close-OpenWindow {
    [CmdletBinding(DefaultParameterSetName = "ByCaption")]
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            $windows = Get-OpenWindow

            Set-Variable `
                -Name MyTest `
                -Scope Global `
                -Value $windows

            return $windows.Caption | where {
                "`"$_`"" -like "`"$C*`""
            } | foreach {
                "`"$_`""
            } | foreach {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
        })]
        [Parameter(
            ParameterSetName = 'ByCaption',
            Position = 0
        )]
        [String]
        $Caption,

        [ArgumentCompleter({
            Param($A, $B, $C)

            $windows = Get-OpenWindow

            Set-Variable `
                -Name MyTest `
                -Scope Global `
                -Value $windows

            return $(
                $windows.HandleId |
                foreach {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                }
            )
        })]
        [Parameter(ParameterSetName = 'ByHandleId')]
        [String]
        $HandleId,

        [Parameter(
            ParameterSetName = 'FromPipeline',
            ValueFromPipeline
        )]
        [PsCustomObject[]]
        $InputObject
    )

    Begin {
        $list = @()
    }

    Process {
        $list += @($InputObject)
    }

    End {
        $windows = switch ($PsCmdlet.ParameterSetName) {
            'FromPipeline' {
                $list
            }

            'ByCaption' {
                Get-OpenWindow | where { $_.Caption -like "$Caption*" }
            }

            'ByHandleId' {
                Get-OpenWindow | where { $_.HandleId -eq $HandleId }
            }
        }

        foreach ($window in $windows) {
            [PsCustomObject]@{
                Success = [WinAPI]::CloseWindow($window.HandleId)
                HandleId = $window.HandleId
                Caption = $window.Caption
                Visible = $window.Visible
            }
        }
    }
}

function Test-OpenWindow {
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            $windows = Get-OpenWindow

            Set-Variable `
                -Name MyTest `
                -Scope Global `
                -Value $windows

            return $windows.Caption | where {
                "`"$_`"" -like "`"$C*`""
            } | foreach {
                "`"$_`""
            } | foreach {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
        })]
        [Parameter(
            ParameterSetName = 'ByCaption',
            Position = 0
        )]
        [String]
        $Caption,

        [ArgumentCompleter({
            Param($A, $B, $C)

            $windows = Get-OpenWindow

            Set-Variable `
                -Name MyTest `
                -Scope Global `
                -Value $windows

            return $(
                $windows.HandleId |
                foreach {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                }
            )
        })]
        [Parameter(ParameterSetName = 'ByHandleId')]
        [String]
        $HandleId
    )

    switch ($PsCmdlet.ParameterSetName) {
        'ByCaption' {
            $(Get-OpenWindow -Caption $Caption).Count -ne 0
        }

        'ByHandleId' {
            $(Get-OpenWindow -HandleId $HandleId).Count -ne 0
        }
    }
}

<#
.LINK
Url: <https://learn.microsoft.com/en-us/windows/win32/api/dwmapi/nf-dwmapi-dwmgetwindowattribute>
Retrieved: 2025-01-29

.LINK
Url: <https://learn.microsoft.com/en-us/answers/questions/522265/movewindow-and-setwindowpos-is-moving-window-for-e>
Retrieved: 2025-01-29
#>
function Get-OpenWindowRect {
    Param(
        $HandleId
    )

    # Get window position and size
    $result = [WinAPI]::GetWindowLogicalRectangle([IntPtr]$HandleId)

    [pscustomobject]@{
        Left = $result[0]
        Top = $result[1]
        Width = $result[2]
        Height = $result[3]
    }
}

New-Alias `
    -Name focusw `
    -Value Set-ForegroundOpenWindow `
    -Scope Global `
    -Option ReadOnly `
    -Force

