<#
    .LINK
    Link: https://evotec.xyz/remove-item-access-to-the-cloud-file-is-denied-while-deleting-files-from-onedrive/
    Retrieved: 2021_11_02
#>
function Remove-NtfsItem {
    # [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(ValueFromPipeline)]
        [String[]]
        $Path
    )

    <#
    Begin {
        Set-StrictMode -Off
    }
    #>

    Process {
        foreach ($item in $Path) {
            $literal = Get-Item $item

            <#
            if ($WhatIf) {
                Write-Output "WhatIf: Removing $($literal.FullName)"
                continue
            }
            #>

            if ($literal) {
                $literal.Delete($true)
            }
        }
    }
}

