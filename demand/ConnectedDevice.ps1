<#
.DESCRIPTION
Tags: connected, device
#>

function Get-ConnectedDeviceItem {
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

    function Select-Subtree {
        Param(
            $InputObject,
            $Query
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
                { $_ -is [pscustomobject] } {
                    foreach ($property in $subquery.PsObject.Properties) {
                        $folder.Items() |
                        where {
                            $_.Name.ToLower() -eq $property.Name.ToLower()
                        } |
                        foreach {
                            [pscustomobject]@{
                                "$($_.Name)" = Select-Subtree `
                                    -InputObject $_ `
                                    -Query $property.Value
                            }
                        }
                    }
                }

                { $_ -is [string] } {
                    $folder.Items() |
                    where {
                        $_.Name.ToLower() -eq $subquery.ToLower()
                    } |
                    foreach {
                        $temp = [pscustomobject]@{
                            "$($_.Name)" = $_
                        }

                        $deviceAction = {
                            $dest = $Parameters.Destination
                            $datetime = Get-Date -Format 'yyyy-MM-dd-HHmmss' # Uses DateTimeFormat

                            if (-not (Test-Path $dest)) {
                                $dest = mkdir $dest | foreach FullName
                            }

                            $dest = mkdir (Join-Path $dest $datetime) | foreach FullName
                            $shell = New-Object -ComObject Shell.Application

                            $shell.
                                NameSpace($dest).
                                ($Parameters.MethodName)($Parameters.ComObject, $Parameters.Option)
                        }

                        $deviceFunction = {
                            Param($Destination)

                            $datetime = Get-Date -Format 'yyyy-MM-dd-HHmmss' # Uses DateTimeFormat

                            if (-not (Test-Path $Destination)) {
                                $Destination = mkdir $Destination | foreach FullName
                            }

                            $Destination = mkdir (Join-Path $Destination $datetime) | foreach FullName
                            $shell = New-Object -ComObject Shell.Application

                            $shell.
                                NameSpace($Destination).
                                ($Parameters.MethodName)($Parameters.ComObject, $Parameters.Option)
                        }

                        $save = New-Closure `
                            -Parameters $([pscustomobject]@{
                                Destination = $Destination
                                Options = $FILESYSTEM_DO_NOT_PROMPT
                                ComObject = $_
                                MethodName = 'CopyHere'
                            }) `
                            -ScriptBlock $deviceAction

                        $move = New-Closure `
                            -Parameters $([pscustomobject]@{
                                Destination = $Destination
                                Options = $FILESYSTEM_DO_NOT_PROMPT
                                ComObject = $_
                                MethodName = 'MoveHere'
                            }) `
                            -ScriptBlock $deviceAction

                        $saveTo = New-Closure `
                            -Parameters $([pscustomobject]@{
                                Options = $FILESYSTEM_DO_NOT_PROMPT
                                ComObject = $_
                                MethodName = 'CopyHere'
                            }) `
                            -ScriptBlock $deviceFunction

                        $moveTo = New-Closure `
                            -Parameters $([pscustomobject]@{
                                Options = $FILESYSTEM_DO_NOT_PROMPT
                                ComObject = $_
                                MethodName = 'MoveHere'
                            }) `
                            -ScriptBlock $deviceFunction

                        $temp | Add-Member `
                            -MemberType ScriptMethod `
                            -Name 'Save' `
                            -Value $save

                        $temp | Add-Member `
                            -MemberType ScriptMethod `
                            -Name 'Move' `
                            -Value $move

                        $temp | Add-Member `
                            -MemberType ScriptMethod `
                            -Name 'SaveTo' `
                            -Value $saveTo

                        $temp | Add-Member `
                            -MemberType ScriptMethod `
                            -Name 'MoveTo' `
                            -Value $moveTo

                        $temp
                    }
                }

                default {
                    Write-Host "[$_]: Whoops."
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

    $saveTo = $shell.NameSpace($Destination)

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
                -Query $select
        }
    }
}

