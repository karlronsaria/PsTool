function Send-Beep {
    [Console]::Beep(2000, 500)
}

function Get-LocationString {
    return (Get-Location).Path
}

function Get-DateString {
    return Get-Date -Format yyyy_MM_dd # Uses DateTimeFormat
}

function Get-DateTimeString {
    return Get-Date -Format yyyy_MM_dd_HHmmss # Uses DateTimeFormat
}

New-Alias `
    -Name loc `
    -Value Get-LocationString `
    -Scope Global `
    -Option ReadOnly `
    -Force

New-Alias `
    -Name gd `
    -Value Get-DateString `
    -Scope Global `
    -Option ReadOnly `
    -Force

New-Alias `
    -Name gdt `
    -Value Get-DateTimeString `
    -Scope Global `
    -Option ReadOnly `
    -Force

<#
.LINK
Url: <https://stackoverflow.com/questions/20886243/press-any-key-to-continue>
Retrieved: 2023_10_11

.LINK
Url: <https://stackoverflow.com/users/2092588/jerry-g>
Retrieved: 2023_10_11

.LINK
Url: <https://stackoverflow.com/users/3437608/cullub>
Retrieved: 2023_10_11
#>
function Start-Pause {
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

function ConvertTo-Hashtable {
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
Retrieved: 2023_10_11
#>
function Get-ShortName {
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

                # # OLD: 2020_07_09
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

function Set-Title {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $Title
    )

    Process {
        $host.UI.RawUi.WindowTitle = $Title
    }
}

