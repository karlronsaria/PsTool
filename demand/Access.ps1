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
    }
"@

function Get-OpenWindow {
    $listName = (
        "$((Get-Item ($PsScriptRoot)).FullName)$('_' * 8)".GetEnumerator() |
            sort { Get-Random } |
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
                  Title = [User32]::GetWindowTitle($hwnd)
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
            $_.Visible -and $_.Title.Trim()
        }

    Remove-Variable `
        -Scope Global `
        -Name $listName
}

function Set-ForegroundWindowByTitle {
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            $windows = Get-OpenWindow

            Set-Variable `
                -Name MyTest `
                -Scope Global `
                -Value $windows

            return $windows.Title | where {
                "`"$_`"" -like "`"$C*`""
            } | foreach {
                "`"$_`""
            }
        })]
        [String]
        $WindowTitle
    )

    $closure = New-Closure `
        -Parameters $WindowTitle `
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

