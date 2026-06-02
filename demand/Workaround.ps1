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
