<#
.DESCRIPTION
Tags: package, moniker, manager
#>

function Get-PackageMoniker {
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            $path = [PsCustomObject]@{
                Choco = "C:\shortcut\dos\backup\choco\package*"
                Winget = "C:\shortcut\dos\backup\winget\package*"
            }

            $choco = return [xml](dir $path.Choco | Get-Content | Out-String) |
                foreach ChildNodes |
                foreach package |
                foreach id |
                where { $_ }

            $winget = dir $path.Winget |
                Get-Content |
                ConvertFrom-Json |
                foreach Sources |
                foreach Packages |
                foreach PackageIdentifier |
                where { $_ } |
                foreach { ($_.Split('.') | select -Skip 1) -Join '.' }

            $list = @($choco) + @($winget)

            $suggest = $list |
                where { $_ -like "$C*" }

            return $(
                if (@($suggest | where { $_ }).Count -gt 0) {
                    $suggest
                }
                else {
                    $list
                }
            )
        })]
        [string]
        $Name
    )

    $path = [PsCustomObject]@{
        Choco = "C:\shortcut\dos\backup\choco\package*"
        Winget = "C:\shortcut\dos\backup\winget\package*"
    }

    $choco = [xml](dir $path.Choco | Get-Content | Out-String) |
        foreach ChildNodes |
        foreach package |
        foreach id |
        where { $_ } |
        foreach {
            [PsCustomObject]@{
                Moniker = $_
                Manager = 'choco'
            }
        }

    $winget = dir $path.Winget |
        Get-Content |
        ConvertFrom-Json |
        foreach Sources |
        foreach Packages |
        foreach PackageIdentifier |
        where { $_ } |
        foreach { ($_.Split('.') | select -Skip 1) -Join '.' } |
        foreach {
            [PsCustomObject]@{
                Moniker = $_
                Manager = 'winget'
            }
        }

    $list = @($choco) + @($winget)

    return $(
        if ($Name) {
            $list | where Moniker -like "$Name*"
        }
        else {
            $list
        }
    )
}

