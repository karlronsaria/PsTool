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
        $packages = $packages | where {
            $_.DisplayName -like $DisplayName
        }
    }

    if ($DisplayVersion) {
        $packages = $packages | where {
            $_.DisplayVersion -like $DisplayVersion
        }
    }

    if ($Publisher) {
        $packages = $packages | where {
            $_.Publisher -like $Publisher
        }
    }

    $packages = $packages |
        where { $_.DisplayName } |
        foreach {
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
        $packages = $packages | where {
            $null -ne $_.InstallDate -and `
            $_.InstallDate -le $InstallByDate
        }
    }

    return $packages
}
