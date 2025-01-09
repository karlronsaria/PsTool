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

            return $windows.HandleId
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
                  HandleId = $hwnd
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
                    [User32]::SetForegroundWindow($hWnd)
                    return $false
                }

                return $true
            }
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

            return $windows.HandleId
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
                Success = [User32]::DestroyWindow($window.HandleId)
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

            return $windows.HandleId
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

New-Alias `
    -Name focusw `
    -Value Set-ForegroundOpenWindow `
    -Scope Global

