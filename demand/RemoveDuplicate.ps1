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
        where { $_ } |
        foreach -Begin {
            $table = @{}
            $duplicates = @{}
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

function Get-ItemDuplicate {
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
        Get-ItemDuplicatePair |
        group -Property ReferenceObject |
        foreach {
            [PsCustomObject]@{
                ReferenceObject = $_.Name
                DifferenceObject = $_.Group.DifferenceObject
            }
        }
    }
}

function Move-ItemDuplicate {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        $Directory,

        [Switch]
        $ExcludeReference
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
        Get-ItemDuplicate |
        foreach -Begin {
            $count = 0
        } -Process {
            $dirName = Join-Path $Directory ("/__dup{0:d3}" -f $count)
            $refName = (Get-Item $_.ReferenceObject).Name
            $count = $count + 1
            mkdir $dirName -ErrorAction SilentlyContinue

            if (-not $ExcludeReference) {
                Move-Item $_.ReferenceObject $dirName
            }

            @($_.DifferenceObject) | foreach {
                $diffName = (Get-Item $_).Name
                $diffPath = Join-Path $dirName $diffName
                $newPath = $diffPath

                # If new path already exists, add a time stamp to the end
                while ((Test-Path $newPath)) {
                    $item = Get-Item $_
                    $newName = "$($item.BaseName)_$(Get-Date -Format HHmmss)$($item.Extension)"
                    $newPath = Join-Path $dirName $newName
                }

                Move-Item $_ $newPath
            }
        }
    }
}

