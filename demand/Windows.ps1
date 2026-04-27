<#
.DESCRIPTION
Tags: windows, installed, programs
#>
function Get-LocalPackage {
    [OutputType([PsCustomObject[]])]
    Param(
        [String]
        $DisplayName,

        [String]
        $DisplayVersion,

        [String]
        $Publisher,

        [DateTime]
        $InstallByDate,

        [Switch]
        $Full
    )

    $pattern =
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

    if (-not $Full) {
        $packages = Get-ItemProperty $pattern |
            Select-Object `
                DisplayName,
                DisplayVersion,
                Publisher,
                InstallDate
    }

    if ($DisplayName) {
        $packages = $packages | Where-Object {
            $_.DisplayName -like $DisplayName
        }
    }

    if ($DisplayVersion) {
        $packages = $packages | Where-Object {
            $_.DisplayVersion -like $DisplayVersion
        }
    }

    if ($Publisher) {
        $packages = $packages | Where-Object {
            $_.Publisher -like $Publisher
        }
    }

    $packages = $packages |
        Where-Object { $_.DisplayName } |
        ForEach-Object {
            [PsCustomObject]@{
                DisplayName = $_.DisplayName
                DisplayVersion = $_.DisplayVersion
                Publisher = $_.Publisher
                InstallDate = if ($_.InstallDate) {
                    [DateTime]::ParseExact(
                        $_.InstallDate,
                        "yyyyMMdd",
                        $null
                    )
                }
                else {
                    $null
                }
            }
        }

    if ($InstallByDate) {
        $packages = $packages | Where-Object {
            $null -ne $_.InstallDate -and `
            $_.InstallDate -le $InstallByDate
        }
    }

    return $packages
}
