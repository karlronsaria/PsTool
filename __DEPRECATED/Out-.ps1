<#
.ISSUE
Command

```powershell
dir \note | Out-NotepadPlusPlus
```

Expected

```
    Directory: C:\note


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----         5/24/2021   4:30 AM                banter
d-----         5/18/2021   8:08 PM                dev
d-----         5/25/2021  12:54 AM                howto
```

Actual

```
    Directory: C:\note


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----         5/24/2021   4:30 AM                banter





    Directory: C:\note


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----         5/18/2021   8:08 PM                dev





    Directory: C:\note


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----         5/25/2021  12:54 AM                howto
```
#>
function Out-NotepadPlusPlus {
    [Alias("Out-Npp")]
    [CmdletBinding(DefaultParameterSetName = "ByObject")]
    Param(
        [Parameter(
            ParameterSetName = "ByObject",
            ValueFromPipeline = $true
        )]
        [PSObject[]]
        $InputObject,

        [Parameter(
            ParameterSetName = "ByStream",
            ValueFromPipeline = $true
        )]
        $Stream,

        [Switch]
        $WhatIf
    )

    Begin {
        $buf = New-Object System.Text.StringBuilder

        $method = if ($NoNewLine) {
            "Append"
        }
        else {
            "AppendLine"
        }
    }

    Process {
        if ($PsCmdlet.ParameterSetName -eq "ByStream") {
            $InputObject = $Stream | Out-String
        }

        $InputObject | foreach {
            $buf.$method($_.ToString()) | Out-Null
        }
    }

    End {
        $command =
            "notepad++ -qt=`"$($buf.ToString())`" -qSpeed3 -multiInst"

        if ($WhatIf) {
            return [PsCustomObject]@{
                InputObject = $InputObject
                Command = $command
            }
        }

        Write-Verbose "Command: $command"
        Invoke-Expression -Command $command
    }
}
