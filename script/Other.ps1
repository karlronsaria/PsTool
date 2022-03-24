
function Send-Beep { [Console]::Beep(2000, 500) }

function loc { return (Get-Location).Path }

<#
    .LINK
        https://stackoverflow.com/questions/20886243/press-any-key-to-continue

    .LINK
        https://stackoverflow.com/users/2092588/jerry-g

    .LINK
        https://stackoverflow.com/users/3437608/cullub
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
        $InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }

    $table = @{}

    switch ($InputObject.GetType().Name) {
        'PsObject' {
            $InputObject | % {
                $table[$_.Name] = $_.Value
            }
        }

        'PsCustomObject' {
            $table = ConvertTo-Hashtable `
                -InputObject $InputObject.PsObject
        }
    }

    return $table
}

<#
    .LINK
        https://devblogs.microsoft.com/scripting/use-powershell-to-display-short-file-and-folder-names/
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
