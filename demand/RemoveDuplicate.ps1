<#
Tags: duplicate
#>

function Get-ItemDuplicatePair {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    Begin {
        $list = @()
    }

    Process {
        $list += @($InputObject)
    }

    End {
        $list |
        foreach -Begin {
            $table = @{}
            $count = 0
        } -Process {
            Write-Progress `
                -Activity "Reading" `
                -Status "$count of $($list.Count) files" `
                -PercentComplete (100 * $count / $list.Count)

            $key = $_ |
                Get-Content |
                Out-String

            $refName = $table[$key]
            $diffName = $_.FullName

            if ($null -eq $refName) {
                $table[$key] = $diffName
            }
            else {
                [PsCustomObject]@{
                    ReferenceObject = $refName
                    DifferenceObject = $diffName
                }
            }

            $count = $count + 1
        } -End {
            Write-Progress `
                -Activity "Reading" `
                -Status "$count of $($list.Count) files" `
                -PercentComplete 100 `
                -Complete
        }
    }
}

function Move-ItemDuplicatePair {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        $Directory
    )

    Begin {
        $list = @()

        $Directory = if (-not $Directory) {
            Get-Location
        }
    }

    Process {
        $list += @($InputObject)
    }

    End {
        $list |
        Get-ItemDuplicatePair |
        foreach -Begin {
            $count = 0
        } -Process {
            $dirName = Join-Path $Directory ("/__dup{0:d3}" -f $count)
            $count = $count + 1
            mkdir $dirName -ErrorAction SilentlyContinue
            Move-Item $_.ReferenceObject $dirName
            Move-Item $_.DifferenceObject $dirName
        }
    }
}

