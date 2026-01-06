<#
.DESCRIPTION
Tags: disk
#>
function Dismount-DiskImage {
    Param(
        [ArgumentCompleter({
            return Get-PsDrive |
                where { $_.Provider.Name -eq 'FileSystem' } |
                foreach Name |
                where { $_ -notin @('C', 'Temp') }
        })]
        [string]
        $DriveLetter
    )

    if (-not $DriveLetter) {
        $DriveLetter = Get-PsDrive |
            where { $_.Provider.Name -eq 'FileSystem' } |
            foreach Name |
            where { $_ -notin @('C', 'Temp') } |
            select -First 1
    }

    $shell = New-Object -ComObject Shell.Application
    $drive = $shell.Namespace(17).ParseName("${DriveLetter}:")

    if (-not $drive) {
        throw "Drive not found"
    }

    $drive.InvokeVerb('Eject')
}

