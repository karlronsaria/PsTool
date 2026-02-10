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
