function Get-DemandScript {
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            $setting =
                cat "$PsScriptRoot\..\res\demandscript.setting.json" |
                ConvertFrom-Json

            $dir = Get-DemandScript

            return $(
                $setting.
                Patterns.
                Value |
                foreach {
                    $dir | sls $_
                } |
                foreach {
                    $_.Matches |
                    foreach {
                        $_ -split "\s"
                    }
                } |
                where {
                    $_ -like "$C*"
                }
            )
        })]
        [Parameter(Position = 0)]
        [String[]]
        $InputObject,

        [ValidateSet('Or', 'And')]
        [String]
        $Mode = 'Or',

        [Switch]
        $Source,

        [Switch]
        $AllProfiles
    )

    function Get-DemandMatch {
        Param(
            [Parameter(ValueFromPipeline = $true)]
            [System.IO.FileSystemInfo]
            $InputObject,

            [String[]]
            $Pattern
        )

        if ($Pattern.Count -eq 0) {
            $Pattern =
                (cat "$PsScriptRoot\..\res\demandscript.setting.json" |
                ConvertFrom-Json).
                Patterns.
                Value
        }

        foreach ($item in $Pattern) {
            $InputObject |
            sls $item |
            foreach {
                [PsCustomObject]@{
                    Capture = $_
                    Matches =
                        $_.Matches |
                        foreach {
                            $_ -split "\s"
                        }
                }
            }
        }
    }

    $setting = cat "$PsScriptRoot/../res/demandscript.setting.json" |
        ConvertFrom-Json

    $profiles = $(if ($AllProfiles) {
        $setting.Profiles
    }
    else {
        $setting.Profiles |
        where {
            $_.Version -eq $setting.DefaultVersion
        }
    }).
    Location

    if ($InputObject.Count -eq 0) {
        return $(
            $profiles |
            foreach {
                "$env:OneDrive/Documents/$_/Scripts/*/demand/*.ps1"
            } |
            dir
        )
    }

    Get-DemandScript |
    Get-DemandMatch |
    where {
        $diff = diff $_.Matches $InputObject

        ($Mode -eq 'Or' -or
            $diff.SideIndicator -notcontains '=>') -and
            $diff.Count -lt ($_.Matches.Count + $InputObject.Count)
    } |
    foreach {
        $_.Capture.Path
    } |
    select -Unique |
    foreach {
        if ($Source) { . $_ }

        $_
    }
}

