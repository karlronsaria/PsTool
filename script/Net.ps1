<#
.SYNOPSIS
A captive portal network blocks access until a user logs in. This command forces the
system to open the portal, skipping the process of interacting with the taskbar.

.DESCRIPTION
Tags: msftconnect captiveportal neverssl

A captive portal network blocks access until a user logs in. This command forces the
system to open the portal, skipping the process of interacting with the taskbar.

Captive portals intercept plain HTTP, not HTTPS, requests.
The link <http://neverssl.com> is designed to trigger captive portals.
HTTPS requests, however, will fail silently.

Windows uses a connectivity check system called the Network Connectivity Status Indicator (NCSI). This can be voluntarily triggered using the test page,

  <http://msftconnecttest.com/redirect>

or

  <http://msftconnecttest.com/connecttest.txt>.

If the page won't open, try flushing the DNS and renewing IP, and then retry.

  ipconfig /flushdns
  ipconfig /release
  ipconfig /renew

.LINK
Url: <http://neverssl.com>
Retrieved: 2026-02-14

.LINK
Url: <http://msftconnecttest.com>
Retrieved: 2026-02-14

.LINK
Url: <https://learn.microsoft.com/en-us/windows-server/networking/ncsi/ncsi-overview>
Retrieved: 2026-02-14
#>
function Connect-NetCaptivePortal {
    Param(
        [ValidateSet(
            "http://neverssl.com",
            "http://1.1.1.1",
            "http://www.msftconnecttest.com/redirect",
            "http://www.msftconnecttest.com/connecttest.txt"
        )]
        $Url = "http://neverssl.com",

        [switch]
        $ResetIP,

        [switch]
        $PassThru
    )

    if ($ResetIP) {
        ipconfig /flushdns
        ipconfig /release
        ipconfig /renew
    }

    $osIsWin = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::Windows
    )

    if ($osIsWin) {
        start $Url
    }
    else {
        curl $Url
    }

    if ($PassThru) {
        $Url
    }
}

