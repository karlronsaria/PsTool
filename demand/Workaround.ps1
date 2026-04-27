#Requires -RunAsAdmin

<#
.DESCRIPTION
Tags: wuauserv
#>
function Suspend-WindowsUpdate {
    "Suspending Windows Update"
    "Note: This terminal instance has been converted to a spin-lock."
    "Press 'Ctrl + C' to stop."

    while ($true) {
        if ((Get-Service | Where-Object { $_.Name -like "wuauserv" }).Status -ne "Stopped") {
            Get-Date -Format "yyyy-MM-dd HH:mm:ss`n" # Uses DateTimeFormat
            net stop wuauserv
            "`n"
        }
    }
}

<#
.DESCRIPTION
Tags: alert, privacy, consumeraction

Windows 11 (win11) caught storing quiet screenshots.
Use this command to remove and block Microsoft spyware.

.LINK
What: Windows 11 is Hiding Your Personal Data in THIS Folder
Url: <https://www.youtube.com/watch?v=x8GA1GnEl3o>
Retrieved: 2025-11-06
#>
function Clear-QuietCapture {
    [CmdletBinding()]
    Param(
        [switch]
        $SetInRegistry
    )

    $itemPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ScreenClipBlock"
    $itemName = "BlockScreenClip"
    $itemType = 'DWord'
    $itemValue = 1

    $item = Get-ItemProperty `
        -Path $itemPath |
        ForEach-Object $itemName

    if ($item -eq $itemValue) {
        if ($SetInRegistry) {
            "SetInRegistry: Quiet screen capture is already blocked on your device."
        }
    }
    else {
        if ($SetInRegistry) {
            New-ItemProperty `
                -Path $itemPath `
                -Name $itemName `
                -PropertyType $itemType `
                -Value $itemValue
        }
        else {
            $cmdletName = Get-PSCallStack |
                Select-Object -ExpandProperty FunctionName -Skip 1 -First 1

            "Quiet screen capture is not blocked on your device."
            "Consider disabling it indefinitely with"
            ""
            "    $($PsStyle.Foreground.BrightYellow)$cmdletName -SetInRegistry$($PsStyle.Reset)"
            ""
        }
    }

    Get-ChildItem `
        -Path "$env:LOCALAPPDATA\Packages" `
        -Recurse `
        -Include *.dat, *ScreenClip `
        -ErrorAction SilentlyContinue |
    Remove-Item `
        -Force `
        -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
Permanantly and forcefully removes Microsoft Edge, and attempts to make auto-reinstall difficult for the next update of Windows.

.DESCRIPTION
Tags: alert, privacy, consumeraction

Permanantly and forcefully removes Microsoft Edge, and attempts to make auto-reinstall difficult for the next update of Windows. Be prepared to call this script whenever Windows updates.

.LINK
- What: motive
- Url: <https://www.youtube.com/watch?v=w8EGomuEX8s&t=140s>
- Retrieved: 2024-02-02
.LINK
- What: howto uninstall, prevent reinstall
- Url: <https://www.tomsguide.com/how-to/how-to-uninstall-microsoft-edge>
- Retrieved: 2024-02-02
.LINK
- What: howto remove AppX package
- Url: <https://www.process.st/how-to/uninstall-microsoft-edge/>
- Retrieved: 2024-02-02
#>
function Uninstall-MsEdge {
    # *********************
    # * --- Uninstall --- *
    # *********************

    $app_path = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\*\Installer\setup.exe"
    $app_args = "setup.exe --uninstall --system-level --verbose-logging --force-uninstall"

    Get-ChildItem $app_path -Recurse |
    ForEach-Object {
        Invoke-Expression "$app_path $app_args"
    }

    # ********************************
    # * --- Discourage Reinstall --- *
    # ********************************

    $reg_path = "HKLM:\SOFTWARE\Microsoft\EdgeUpdate"
    $reg_name = "DoNotUpdateToEdgeWithChromium"
    $reg_type = 'REG_DWORD'

    if (-not (Test-Path $reg_path)) {
        New-Item `
            -Path $reg_path `
            -Force
    }

    New-ItemProperty `
        -Path $reg_path `
        -Name $reg_name `
        -PropertyType $reg_type `
        -Value 1 `
        -Force

    # *******************************
    # * --- Remove AppX Package --- *
    # *******************************

    Get-AppXPackage `
        -Name "*MicrosoftEdge*" `
        -AllUsers |
    Remove-AppXPackage `
        -Force
}

