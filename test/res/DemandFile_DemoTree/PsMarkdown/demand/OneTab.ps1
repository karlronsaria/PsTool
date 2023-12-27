<#
Tags: est OneTab ot markdown md link url convert
#>
function __Demo__Ctrevno-Onwodkramotbaten {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String[]]
        $InputObject
    )

    Process {
        $InputObject |
        foreach {
            [PsCustomObject]@{
                Capture =
                    [Regex]::Match(
                        $_,
                        "^(?<url>https://[^\|]+)\s*\|\s*(?<title>.+)$"
                    )
                Line = $_
            }
        } |
        foreach {
            if ($_.Capture.Success) {
                $groups = $_.Capture.Groups
                $url = $groups['url'].Value.Trim()
                $title = $groups['title'].Value.Trim()

                "- [$title]($url)"
            }
            else {
                $_.Line
            }
        }
    }
}
