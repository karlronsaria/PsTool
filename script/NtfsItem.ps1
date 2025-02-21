<#
.LINK
Url: <https://evotec.xyz/remove-item-access-to-the-cloud-file-is-denied-while-deleting-files-from-onedrive/>
Retrieved: 2021-11-02
#>
function Remove-NtfsItem {
    # [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String[]]
        $Path,

        [Switch]
        $Recurse
    )

    <#
    Begin {
        Set-StrictMode -Off
    }
    #>

    Process {
        foreach ($item in $Path) {
            $file = Get-Item $item

            <#
            if ($WhatIf) {
                Write-Output "WhatIf: Removing $($file.FullName)"
                continue
            }
            #>

            if ($file) {
                $file.Delete($Recurse)
            }
        }
    }
}

