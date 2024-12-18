<#
Tags: access, accessibility
#>

Import-DemandModule closure

Add-Type @"
    using System;
    using System.Text;
    using System.Runtime.InteropServices;

    public class User32 {
        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern bool IsWindowVisible(IntPtr hWnd);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern IntPtr GetForegroundWindow();

        public static string GetWindowTitle(IntPtr hWnd) {
            StringBuilder sb = new StringBuilder(1024);
            GetWindowText(hWnd, sb, sb.Capacity);
            return sb.ToString();
        }

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern bool DestroyWindow(IntPtr hWnd);
    }
"@

function Get-OpenWindow {
    $listName = (
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
                  Handle = $hwnd
                  Caption = [User32]::GetWindowTitle($hwnd)
                  Visible = [User32]::IsWindowVisible($hwnd)
                }
              ))

            return $true
        }

    [User32]::EnumWindows($closure, [IntPtr]::Zero) | Out-Null

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
            }
        })]
        [String]
        $Caption
    )

    $closure = New-Closure `
        -Parameters $Caption `
        -ScriptBlock {
            Param($hWnd, $lParam)

            if ([User32]::GetWindowTitle($hWnd).Trim() -eq $Parameters) {
                [User32]::SetForegroundWindow($hWnd)
                return $false
            }

            return $true
        }

    [User32]::EnumWindows([User32+EnumWindowsProc] $closure, [IntPtr]::Zero) | Out-Null
}

function Remove-OpenWindow {
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

            return $windows.Handle
        })]
        [Parameter(ParameterSetName = 'ByHandleId')]
        [String]
        $Id,

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
                Get-OpenWindow | where { $_.Caption -eq $Id }
            }
        }

        foreach ($window in $windows) {
            [PsCustomObject]@{
                Success = [User32]::DestroyWindow($window.Handle)
                Handle = $window.Handle
                Caption = $window.Caption
                Visible = $window.Visible
            }
        }
    }
}

