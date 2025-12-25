<#
.DESCRIPTION
Tags: MTP, connected, device
#>

function Get-MtpDeviceItem {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param(
        [Parameter(
            ParameterSetName = 'Name'
        )]
        [ArgumentCompleter({
            Param($A, $B, $C)

            $NAMESPACE_THIS_PC_CODE = 17
            $shell = New-Object -ComObject Shell.Application
            $fileSystem = $shell.NameSpace($NAMESPACE_THIS_PC_CODE)
            $devices = $fileSystem.Items() | where { -not $_.IsFileSystem }
            $suggest = $devices | where { $_.Name -like "$C*" }

            $(if ($suggest) {
                $suggest
            }
            else {
                $devices
            }) |
            foreach { $_.Name } |
            foreach {
                if ($_ -like "* *") {
                    "`"$_`""
                }
                else {
                    $_
                }
            }
        })]
        [string]
        $Name,

        [Parameter(
            ParameterSetName = 'Type'
        )]
        [ArgumentCompleter({
            Param($A, $B, $C)

            $NAMESPACE_THIS_PC_CODE = 17
            $shell = New-Object -ComObject Shell.Application
            $fileSystem = $shell.NameSpace($NAMESPACE_THIS_PC_CODE)
            $devices = $fileSystem.Items() | where { -not $_.IsFileSystem }
            $suggest = $devices | where { $_.Type -like "$C*" }

            $(if ($suggest) {
                $suggest
            }
            else {
                $devices
            }) |
            foreach { $_.Type } |
            foreach {
                if ($_ -like "* *") {
                    "`"$_`""
                }
                else {
                    $_
                }
            }
        })]
        [string]
        $Type,

        [string[]]
        $Query,

        $Destination
    )

    $NAMESPACE_THIS_PC_CODE = 17
    $FILESYSTEM_DO_NOT_PROMPT = 16

    # Uses DateTimeFormat
    $dateTimeFormat = "$PsScriptRoot/../res/setting.json" |
        Get-Item |
        Get-Content |
        ConvertFrom-Json |
        foreach { $_.DateTimeFormat }

    function New-Closure {
        Param(
            [ScriptBlock]
            $ScriptBlock,

            $Parameters
        )

        return & {
            Param($Parameters)
            return $ScriptBlock.GetNewClosure()
        } $Parameters
    }

    function Get-DeviceTree {
        Param($InputObject)

        if ($null -eq $InputObject) {
            return
        }

        $folder = $InputObject.GetFolder

        if ($null -eq $folder) {
            return $folder
        }

        $folder.Items() |
        foreach {
            [pscustomobject]@{
                "$($_.Name)" = Get-DeviceTree -InputObject $_
            }
        }
    }

    function Add-Methods {
        Param(
            $InputObject,
            $Destination,
            $ComObject
        )

        $deviceAction = {
            $ErrorActionPreference = 'Continue'
            $dest = $Parameters.Destination
            $datetime = Get-Date -Format $Parameters.DateTimeFormat
            $dest = mkdir (Join-Path $dest $datetime) | foreach FullName
            $shell = New-Object -ComObject Shell.Application

            $shell.
                NameSpace($dest).
                ($Parameters.MethodName)($Parameters.ComObject, $Parameters.Option)

            return $dest
        }

        $deviceFunction = {
            Param($Destination)

            $ErrorActionPreference = 'Continue'
            $datetime = Get-Date -Format $Parameters.DateTimeFormat
            $Destination = mkdir (Join-Path $Destination $dateTime) | foreach FullName
            $shell = New-Object -ComObject Shell.Application

            $shell.
                NameSpace($Destination).
                ($Parameters.MethodName)($Parameters.ComObject, $Parameters.Option)

            return $Destination
        }

        $save = New-Closure `
            -Parameters $([pscustomobject]@{
                Destination = $Destination
                Option = $FILESYSTEM_DO_NOT_PROMPT
                DateTimeFormat = $dateTimeFormat
                ComObject = $ComObject
                MethodName = 'CopyHere'
            }) `
            -ScriptBlock $deviceAction

        $move = New-Closure `
            -Parameters $([pscustomobject]@{
                Destination = $Destination
                Option = $FILESYSTEM_DO_NOT_PROMPT
                DateTimeFormat = $dateTimeFormat
                ComObject = $ComObject
                MethodName = 'MoveHere'
            }) `
            -ScriptBlock $deviceAction

        $saveTo = New-Closure `
            -Parameters $([pscustomobject]@{
                Option = $FILESYSTEM_DO_NOT_PROMPT
                DateTimeFormat = $dateTimeFormat
                ComObject = $ComObject
                MethodName = 'CopyHere'
            }) `
            -ScriptBlock $deviceFunction

        $moveTo = New-Closure `
            -Parameters $([pscustomobject]@{
                Option = $FILESYSTEM_DO_NOT_PROMPT
                DateTimeFormat = $dateTimeFormat
                ComObject = $ComObject
                MethodName = 'MoveHere'
            }) `
            -ScriptBlock $deviceFunction

        $upload = New-Closure `
            -Parameters $([pscustomobject]@{
                Option = $FILESYSTEM_DO_NOT_PROMPT
                DateTimeFormat = $dateTimeFormat
                ComObject = $ComObject
            }) `
            -ScriptBlock {
                Param($Source)

                $ErrorActionPreference = 'Continue'
                $fullName = (Get-Item $Source).FullName

                $Parameters.
                    ComObject.
                    GetFolder.
                    CopyHere($fullName, $Parameters.Option)
            }

        $uploadTo = New-Closure `
            -Parameters $([pscustomobject]@{
                Option = $FILESYSTEM_DO_NOT_PROMPT
                DateTimeFormat = $dateTimeFormat
            }) `
            -ScriptBlock {
                Param($Source, $ComObject)

                $ErrorActionPreference = 'Continue'
                $fullName = (Get-Item $Source).FullName

                $ComObject.
                    GetFolder.
                    CopyHere($fullName, $Parameters.Option)
            }

        $InputObject | Add-Member `
            -MemberType ScriptMethod `
            -Name 'Save' `
            -Value $save

        $InputObject | Add-Member `
            -MemberType ScriptMethod `
            -Name 'Move' `
            -Value $move

        $InputObject | Add-Member `
            -MemberType ScriptMethod `
            -Name 'SaveTo' `
            -Value $saveTo

        $InputObject | Add-Member `
            -MemberType ScriptMethod `
            -Name 'MoveTo' `
            -Value $moveTo

        $InputObject | Add-Member `
            -MemberType ScriptMethod `
            -Name 'Upload' `
            -Value $upload

        $InputObject | Add-Member `
            -MemberType ScriptMethod `
            -Name 'UploadTo' `
            -Value $uploadTo

        $InputObject
    }

    function Select-Subtree {
        Param(
            $InputObject,
            $Query,
            $Destination
        )

        if ($null -eq $InputObject) {
            return
        }

        $folder = $InputObject.GetFolder

        if ($null -eq $folder) {
            return $folder
        }

        if ($null -eq $Query) {
            return $folder.Items()
        }

        foreach ($subquery in @($Query | where { $_ })) {
            switch ($subquery) {
                { $_ -is [string] } {
                    $items = $folder.Items() |
                        where {
                            $_.Name.ToLower() -eq $subquery.ToLower()
                        } |
                        where { $_ }

                    if (-not $items) {
                        try {
                            $folder.NewFolder($subquery)
                            Sleep 1
                            $items = @($folder.Items() | where { $_.Name -eq $subquery })
                        }
                        catch {
                            Write-Error "Cannot access device resources. Check your device connection."
                        }
                    }

                    foreach ($item in $items) {
                        Add-Methods `
                            -InputObject $(
                                [pscustomobject]@{
                                    "$($item.Name)" = $item
                                }
                            ) `
                            -Destination $Destination `
                            -ComObject $item
                    }

                    break
                }

                { $_ -is [pscustomobject] } {
                    foreach ($property in $_.PsObject.Properties) {
                        $items = $folder.Items() |
                            where {
                                $_.Name.ToLower() -eq $property.Name.ToLower()
                            } |
                            where { $_ }

                        if (-not $items) {
                            try {
                                $folder.NewFolder($property.Name)
                                Sleep 1
                                $items = @($folder.Items() | where { $_.Name -eq $property.Name })
                            }
                            catch {
                                Write-Error "Cannot access device resources. Check your device connection."
                            }
                        }

                        foreach ($item in $items) {
                            Add-Methods `
                                -InputObject $(
                                    [pscustomobject]@{
                                        "$($item.Name)" = Select-Subtree `
                                            -InputObject $item `
                                            -Query $property.Value `
                                            -Destination $Destination
                                    }
                                ) `
                                -Destination $Destination `
                                -ComObject $item
                        }
                    }

                    break
                }

                default {
                    Write-Host "[$_]: Whoops."
                    break
                }
            }
        }
    }

    $shell = New-Object -ComObject Shell.Application
    $fileSystem = $shell.NameSpace($NAMESPACE_THIS_PC_CODE)
    $devices = $fileSystem.Items() | Where-Object { -not $_.IsFileSystem }
    $filterBy = $PsCmdlet.ParameterSetName

    if (-not $Destination) {
        $Destination = Get-Location | foreach Path
    }

    if ($filterBy -ne 'All') {
        $devices = $devices |
        where {
            $_.($filterBy) -like "$($PsBoundParameters[$filterBy].Value)*"
        }
    }

    if (-not $Query) {
        return $devices
    }

    foreach ($subquery in $Query) {
        $select = $subquery | ConvertFrom-Json -Depth 100

        $devices |
        foreach {
            Select-Subtree `
                -InputObject $_ `
                -Query $select `
                -Destination $Destination
        }
    }
}

