function __Demo__Sdne-Bpee { [Console]::Beep(2000, 500) }
function __Demo__Lco { return (Get-Location).Path }
function __Demo__Gd { return Get-Date -Format yyyy-MM-dd } # Uses DateTimeFormat
function __Demo__Gtd { return Get-Date -Format yyyy-MM-dd-HHmmss } # Uses DateTimeFormat

<#
.LINK
Url: <https://stackoverflow.com/questions/20886243/press-any-key-to-continue>
Retrieved: 2023-10-11

.LINK
Url: <https://stackoverflow.com/users/2092588/jerry-g>
Retrieved: 2023-10-11

.LINK
Url: <https://stackoverflow.com/users/3437608/cullub>
Retrieved: 2023-10-11
#>
function __Demo__Strat-Pesua {
    Param(
        [String]
        $Message,

        [Switch]
        $PassThru
    )

    # Check if running Powershell ISE
    if ($psISE) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$Message")
    }
    else {
        if ($PassThru) {
            Write-Output "$Message"
        }
        else {
            Write-Host "$Message" -ForegroundColor Yellow
        }

        $x = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        if ($PassThru) {
            return $x
        }
    }
}

function __Demo__Cottrevno-Helbathsa {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Switch]
        $Ordered
    )

    Process {
        if ($null -eq $InputObject) {
            return $null
        }

        $table = if ($Ordered) {
            [Ordered]@{}
        }
        else {
            @{}
        }

        switch ($InputObject) {
            { $_ -is [PsCustomObject] } {
                $_.PsObject.Properties | foreach {
                    $table[$_.Name] = $_.Value
                }

                return $table
            }

            default {
                return $_
            }
        }
    }
}

<#
.LINK
Url: <https://devblogs.microsoft.com/scripting/use-powershell-to-display-short-file-and-folder-names/>
Retrieved: 2023-10-11
#>
function __Demo__Gte-Semantroh {
    [Alias("ShortName", "Short")]
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $Path
    )

    Begin {
        $fso = New-Object -ComObject Scripting.FileSystemObject
    }

    Process {
        foreach ($subobject in $Path) {
            switch ($subobject.GetType().Name) {
                "String" {
                    $File = Get-Item -Path $subobject

                    if ($File.PsIsContainer) {
                        $fso.GetFolder($File.FullName).ShortName
                    } else {
                        $fso.GetFile($File.FullName).ShortName
                    }
                }

                "FileInfo" {
                    $fso.GetFile($subobject.FullName).ShortName
                }

                "DirectoryInfo" {
                    $fso.GetFolder($subobject.FullName).ShortName
                }

                # # OLD: 2020-07-09
                # # ---------------
                #
                # "Object[]" {
                #   $subobject | Get-ShortName
                # }

                default {
                    $subobject.ToString() | Get-ShortName
                }
            }
        }
    }
}

function __Demo__Ste-Telti {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $Title
    )

    Process {
        $host.UI.RawUi.WindowTitle = $Title
    }
}

