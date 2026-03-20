<#
.DESCRIPTION
Tags: package, moniker, manager
#>

function Get-PackageMoniker {
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            $activity = "Getting package list..."

            Write-Progress `
                -Activity $activity `
                -PercentComplete 0

            $path = [PsCustomObject]@{
                Choco = "C:\shortcut\dos\backup\choco\packages.config"
                Winget = "C:\shortcut\dos\backup\winget\package.json"
            }

            $cargo = cargo install --list |
                Select-String "^\S+(?= )" |
                foreach Matches |
                foreach Value

            $choco = [xml]($path.Choco | Get-Item | Get-Content | Out-String) |
                foreach ChildNodes |
                foreach package |
                foreach id |
                where { $_ }

            $winget = $path.Winget |
                Get-Item |
                Get-Content |
                ConvertFrom-Json |
                foreach Sources |
                foreach Packages |
                foreach PackageIdentifier |
                where { $_ } |
                foreach {
                    # # (karlr 2026-01-23)
                    # ($_.Split('.') | select -Skip 1) -Join '.'
                    $temp = @($_.Split('.'))

                    switch (@($temp).Count) {
                        1 { @($temp)[0] }
                        default { @($temp | select -Skip 1) -Join '.' }
                    }
                } |
                where { $_ } | # (karlr 2026-01-23)
                select -Unique

            # $npm = npm list -g --depth=0 --json |
            #     ConvertFrom-Json |
            #     foreach dependencies |
            #     foreach PsObject |
            #     foreach Properties |
            #     where MemberType -eq 'NoteProperty' |
            #     foreach Name |
            #     foreach {
            #         $temp = @($_.Split('/'))

            #         switch (@($temp).Count) {
            #             1 { @($temp)[0] }
            #             default { @($temp | select -Skip 1) -Join '/' }
            #         }
            #     }

            $list = @($cargo) + @($choco) + @($winget) # + @($npm)

            $suggest = $list |
                where { $_ -like "$C*" }

            Write-Progress `
                -Activity $activity `
                -Completed

            return $(
                if (@($suggest | where { $_ }).Count -gt 0) {
                    $suggest
                }
                else {
                    $list
                }
            ) | foreach {
                if ($_ -match "\s|\+|\@|\/") {
                    "`"$_`""
                }
                else {
                    $_
                }
            }
        })]
        [Parameter(Position = 0)]
        [string[]]
        $Name
    )

    function Write-PackageProgress {
        Param(
            [string] $Activity,
            [string] $Status,
            [int] $Count,
            [int] $Mod = 100
        )

        Write-Progress `
            -Activity $Activity `
            -Status $Status `
            -PercentComplete $Count

        $Count = $Count + 1

        if ($Count -eq $Mod) {
            $Count = 0
        }

        return $Count
    }

    $activity = "Getting package list..."
    $count = 0

    Write-Progress `
        -Activity $activity `
        -PercentComplete 0

    $path = [PsCustomObject]@{
        Choco = "C:\shortcut\dos\backup\choco\packages.config"
        Winget = "C:\shortcut\dos\backup\winget\package.json"
    }

    $cargo = cargo install --list |
        Select-String "^\S+(?= )" |
        foreach Matches |
        foreach Value |
        foreach {
            Write-PackageProgress `
                -Activity $activity `
                -Status "Cargo: $_" `
                -Count $count

            [PSCustomObject]@{
                Moniker = $_
                Manager = 'cargo'
            }
        }

    $choco = [xml]($path.Choco | Get-Item | Get-Content | Out-String) |
        foreach ChildNodes |
        foreach package |
        foreach id |
        where { $_ } |
        foreach {
            Write-PackageProgress `
                -Activity $activity `
                -Status "Choco: $_" `
                -Count $count

            [PsCustomObject]@{
                Moniker = $_
                Manager = 'choco'
            }
        }

    $winget = $path.Winget |
        Get-Item |
        Get-Content |
        ConvertFrom-Json |
        foreach Sources |
        foreach Packages |
        foreach PackageIdentifier |
        where { $_ } |
        foreach {
            # # (karlr 2026-01-23)
            # ($_.Split('.') | select -Skip 1) -Join '.'
            $temp = @($_.Split('.'))

            switch (@($temp).Count) {
                1 { @($temp)[0] }
                default { @($temp | select -Skip 1) -Join '.' }
            }
        } |
        where { $_ } | # (karlr 2026-01-23)
        select -Unique |
        foreach {
            Write-PackageProgress `
                -Activity $activity `
                -Status "Winget: $_" `
                -Count $count

            [PsCustomObject]@{
                Moniker = $_
                Manager = 'winget'
            }
        }

    # $npm = npm list -g --depth=0 --json |
    #     ConvertFrom-Json |
    #     foreach dependencies |
    #     foreach PsObject |
    #     foreach Properties |
    #     where MemberType -eq 'NoteProperty' |
    #     foreach Name |
    #     foreach {
    #         $temp = @($_.Split('/'))

    #         switch (@($temp).Count) {
    #             1 { @($temp)[0] }
    #             default { @($temp | select -Skip 1) -Join '/' }
    #         }
    #     } |
    #     foreach {
    #         Write-PackageProgress `
    #             -Activity $activity `
    #             -Status "npm: $_" `
    #             -Count $count

    #         [PSCustomObject]@{
    #             Moniker = $_
    #             Manager = 'npm'
    #         }
    #     }

    $list = @($cargo) + @($choco) + @($winget) # + @($npm)

    Write-Progress `
        -Activity $activity `
        -Completed

    return $(
        @($Name | where { $_ }) |
        foreach {
            if ($_) {
                $list | where Moniker -like "$_*"
            }
            else {
                $list
            }
        }
    )
}

function Install-PowerShell {
    Write-Progress `
        -Id 1 `
        -Activity "Running winget" `
        -PercentComplete 50

    $table = winget search Microsoft.PowerShell |
        where { $_ -notmatch "^(\W|\s)*$" }

    Write-Progress `
        -Id 1 `
        -Activity "Running winget" `
        -PercentComplete 100 `
        -Complete

    foreach ($row in $table) {
        $captures = [Regex]::Matches($_, "\S+")

        $name = $captures[0].Value
        $id = $captures[1].Value
        $version = $captures[2].Value
        $source = $captures[3].Value

        if ($id -ne 'Microsoft.PowerShell') {
            continue
        }
    }

    $myVersion = $PsVersionTable.PsVersion
    $upgradeAvailable = $false

    $table | foreach {
        $captures = [Regex]::Matches($_, "\S+")

        $name = $captures[0].Value
        $id = $captures[1].Value
        $version = $captures[2].Value
        $source = $captures[3].Value
        $parts = $version.Split('.')

        $upgradeAvailable = $upgradeAvailable -or (
            $id -eq 'Microsoft.PowerShell' -and (
                [Int]$parts[0] -gt $myVersion.Major -or
                [Int]$parts[1] -gt $myVersion.Minor -or
                [Int]$parts[2] -gt $myVersion.Patch
            )
        )
    }

    if ($upgradeAvailable) {
        winget upgrade --id Microsoft.PowerShell --source winget
    }
}

<#
.LINK
Url: <https://chocolatey.org/docs/installation>
Retrieved: 2019-11-08
#>
function Install-Chocolatey {
    $url = 'https://chocolatey.org/install.ps1'
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($url))
}
