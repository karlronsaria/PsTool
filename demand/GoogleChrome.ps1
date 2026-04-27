#Requires -RunAsAdministrator

<#
.SYNOPSIS
Removes items from local AppData that are associated with Google Chrome cache.

.DESCRIPTION
Removes items from local AppData that are associated with Google Chrome cache.

Without parameters, this does nothing. To use, call with either -Default, -All, or -Include. Make sure Google Chrome is not running, or call with -KillChrome.

Items can be removed which match the following patterns:

    Archived History*
    Cache\*
    Cookies*
    History*
    Login Data*
    Top Sites*
    Visited Links*
    Web Data*

By calling with -Default, this attempts to remove items matching only the following patterns:

    Cache\*
    Cookies*
    Login Data*
    Top Sites*
    Visited Links*
    Web Data*

This only removes local site data. To request removal from any online servers, go to chrome://settings/siteData (as of 22 March 2020).

.LINK
- url: <https://stackoverflow.com/questions/25210330/script-for-clearing-chrome-or-firefox-cache-on-windows>
- retrieved: 2020-03-22

.LINK
- url: <https://superuser.com/questions/292952/chrome-cookies-folder-in-windows-7/293038>
- retrieved: 2020-03-22

.LINK
- url: <https://ephams.com/2015/08/batch-script-clear-chrome-cache-history-cookies/>
- retrieved: 2020-03-22

.LINK
- url: <chrome://settings/siteData>
- retrieved: 2020-03-22
#>
function Remove-GoogleChromeCache {
    [CmdletBinding(DefaultParameterSetName = "UseDefault")]
    Param(
        [Parameter(ParameterSetName = "UseDefault")]
        [Switch]
        $Default,

        [Parameter(ParameterSetName = "UseAll")]
        [Switch]
        $All,

        [Parameter(ParameterSetName = "UseIncludes")]
        [ValidateSet(
            "Archive",
            "Cache",
            "Cookies",
            "History",
            "Login",
            "TopSites",
            "Visits",
            "WebData"
        )]
        [String[]]
        $Include,

        [Switch]
        $Force,

        [Switch]
        $KillChrome,

        [Switch]
        $WhatIf
    )

    $PATH_NAME = "$($env:LOCALAPPDATA)\Google\Chrome\User Data\Default"
    $PROCESS_DISPLAY_NAME = "Google Chrome"
    $PROCESS_NAME = "chrome"
    $DELAY = 3  # Seconds

    $ONLINE_PATH = "chrome://settings/siteData"
    $RETRIEVAL_DATE = "22 March 2020"
    $DISCLAIMER_MSG = "This only removes local site data. To request removal from any online servers, go to $ONLINE_PATH (as of $RETRIEVAL_DATE)."

    $ARCHIVE_PTN  = "Archived History*"
    $CACHE_PTN    = "Cache\*"
    $COOKIES_PTN  = "Cookies*"
    $HISTORY_PTN  = "History*"
    $LOGIN_PTN    = "Login Data*"
    $TOPSITES_PTN = "Top Sites*"
    $VISITS_PTN   = "Visited Links*"
    $WEBDATA_PTN  = "Web Data*"

    function Test-Process([String] $Name) {
        return (Get-Process -Name:$Name -ErrorAction "Ignore").Count -gt 0
    }

    if (-not $KillChrome -and (Test-Process -Name $PROCESS_NAME)) {
        return "Items in the AppData subdirectory cannot be removed while $PROCESS_DISPLAY_NAME is running."
    }

    if ($KillChrome) {
        Write-Output "Closing all $PROCESS_DISPLAY_NAME windows..."

        if (-not $WhatIf) {
            Stop-Process -Name $PROCESS_NAME -Force
        }

        Start-Sleep -Seconds $DELAY
    }

    if ($Default) {
        $Items = @(
            $CACHE_PTN,
            $COOKIES_PTN,
            $LOGIN_PTN,
            $TOPSITES_PTN,
            $VISITS_PTN,
            $WEBDATA_PTN
        )

    } elseif ($All) {
        $Items = @(
            $ARCHIVE_PTN,
            $CACHE_PTN,
            $COOKIES_PTN,
            $HISTORY_PTN,
            $LOGIN_PTN,
            $TOPSITES_PTN,
            $VISITS_PTN,
            $WEBDATA_PTN
        )
    } else {
        $Items = @()

        $Items += if ($Include -contains "Archive") {
            $ARCHIVE_PTN
        }

        $Items += if ($Include -contains "Cache") {
            $CACHE_PTN
        }

        $Items += if ($Include -contains "Cookies") {
            $COOKIES_PTN
        }

        $Items += if ($Include -contains "History") {
            $HISTORY_PTN
        }

        $Items += if ($Include -contains "Login") {
            $LOGIN_PTN
        }

        $Items += if ($Include -contains "TopSites") {
            $TOPSITES_PTN
        }

        $Items += if ($Include -contains "Visits") {
            $VISITS_PTN
        }

        $Items += if ($Include -contains "WebData") {
            $WEBDATA_PTN
        }
    }

    if ($Items.Count -eq 0) {
        Write-Output "Nothing selected."
    } else {
        foreach ($item in $Items) {
            if (Test-Path "$PATH_NAME\$item") {
                if (-not $WhatIf) {
                    Remove-Item "$PATH_NAME\$item" -Force:$Force

                    if (Test-Path "$PATH_NAME\$item") {
                        Write-Output "Failed to remove $item"
                    } else {
                        Write-Output "Successfully removed $item"
                    }

                } else {
                    Write-Output "Successfully removed $item"
                }
            } else {
                Write-Output "No items found matching $item"
            }
        }

        Write-Warning $DISCLAIMER_MSG
    }
}

