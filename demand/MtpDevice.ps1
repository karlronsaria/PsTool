<#
.DESCRIPTION
Tags: MTP, connected, device
#>

class MtpDevice {
    static [int] $NAMESPACE_THIS_PC_CODE = 17
    static [int] $FILESYSTEM_DO_NOT_PROMPT = 16
    static [int] $DEFAULT_DELAY_MS = 500
    static [string] $DEFAULT_DATETIME_FORMAT = 'yyyy-MM-dd-HHmmss' # Uses DateTimeFormat
    static [char] $PATH_SEPARATOR = '/'

    static [hashtable] $ABBREVIATIONS = @{
        'int' = 'Internal storage'
    }

    static [hashtable] $PLEASE_ABBREVIATE = @{
        'Internal storage' = 'int'
    }

    hidden [System.__ComObject] $Com_
    hidden [string] $DateTimeFormat_ = [MtpDevice]::DEFAULT_DATETIME_FORMAT
    hidden [int] $ReadWriteOptions_ = [MtpDevice]::FILESYSTEM_DO_NOT_PROMPT
    hidden [int] $DelayMs_ = [MtpDevice]::DEFAULT_DELAY_MS

    hidden MtpDevice() {
        $this | Add-Member `
            -MemberType ScriptProperty `
            -Name Error `
            -Value { Write-Output "No connected devices found" }
    }

    MtpDevice([System.__ComObject] $Com) {
        $this.Com_ = $Com
    }

    [object]
    Com() {
        return $this.Com_
    }

    [int]
    Delay() {
        return $this.DelayMs_
    }

    [int]
    ReadWriteOptions() {
        return $this.ReadWriteOptions_
    }

    [string]
    DateTimeFormat() {
        return $this.DateTimeFormat_
    }

    [MtpDevice]
    SetDelay([int] $DelayMs) {
        $this.DelayMs_ = $DelayMs
        return $this
    }

    [MtpDevice]
    SetOptions([int] $Options) {
        $this.ReadWriteOptions_ = $Options
        return $this
    }

    [MtpDevice]
    SetDateTimeFormat([string] $DateTimeFormat) {
        $this.DateTimeFormat_ = $DateTimeFormat
        return $this
    }

    hidden [void]
    AddSubtreeItem(
        [string] $Name,
        [System.__ComObject] $FolderCom,
        [scriptblock] $ScriptForEach
    ) {
        $items = $FolderCom.Items() |
            Where-Object {
                $lowerquery = $Name.ToLower()
                $_.Name.ToLower() -in @($lowerquery, [MtpDevice]::ABBREVIATIONS[$lowerquery])
            } |
            Where-Object { $_ }

        if (-not $items) {
            try {
                $FolderCom.NewFolder($Name)
                Start-Sleep -Milliseconds $this.DelayMs_

                $items = @(
                    $FolderCom.Items() |
                    Where-Object {
                        $lowerquery = $Name.ToLower()
                        $_.Name.ToLower() -in @($lowerquery, [MtpDevice]::ABBREVIATIONS[$lowerquery])
                    }
                )
            }
            catch {
                Write-Error "Cannot access device resources. Check your device connection."
            }
        }

        foreach ($item in $items) {
            $value = [MtpDevice]::new($item).
                SetDelay($this.DelayMs_).
                SetOptions($this.Options_).
                SetDateTimeFormat($this.DateTimeFormat_)

            $abbreviation = [MtpDevice]::PLEASE_ABBREVIATE[$item.Name]

            $propName = if ($abbreviation) {
                $abbreviation
            }
            else {
                $item.Name
            }

            $this | Add-Member `
                -MemberType NoteProperty `
                -Name $propName `
                -Value $value

            if ($ScriptForEach) {
                $ScriptForEach.Invoke($value)
            }
        }
    }

    hidden static [scriptblock]
    NewClosure(
        [scriptblock] $ScriptBlock,
        $Parameters
    ) {
        return & {
            Param($Parameters)
            return $ScriptBlock.GetNewClosure()
        } $Parameters
    }

    [MtpDevice]
    MtpPath([string] $Path) {
        return $this.MtpPath($Path, [MtpDevice]::PATH_SEPARATOR)
    }

    [MtpDevice]
    MtpPath([string] $Path, [string] $Separator) {
        if ($null -eq $this.Com_) {
            return $this
        }

        $folder = $this.Com_.GetFolder

        if ($null -eq $folder) {
            return $this
        }

        if ($null -eq $Path) {
            $folder.Items() |
            ForEach-Object {
                $value = [MtpDevice]::new($_).
                    SetDelay($this.DelayMs_).
                    SetOptions($this.Options_).
                    SetDateTimeFormat($this.DateTimeFormat_)

                $this | Add-Member `
                    -MemberType NoteProperty `
                    -Name $_.Name `
                    -Value $value
            }

            return $this
        }

        $parts = $Path.Split($Separator)
        $ptr = $this

        foreach ($part in $parts) {

            $ptr.AddSubtreeItem($part, $ptr.Com_.GetFolder, $null)
            $ptr = $ptr.$part
        }

        return $this
    }

    [MtpDevice]
    Subtree([pscustomobject] $Query) {
        if ($null -eq $this.Com_) {
            return $this
        }

        $folder = $this.Com_.GetFolder

        if ($null -eq $folder) {
            return $this
        }

        if ($null -eq $Query) {
            $folder.Items() |
            ForEach-Object {
                $value = [MtpDevice]::new($_).
                    SetDelay($this.DelayMs_).
                    SetOptions($this.Options_).
                    SetDateTimeFormat($this.DateTimeFormat_)

                $this | Add-Member `
                    -MemberType NoteProperty `
                    -Name $_.Name `
                    -Value $value
            }

            return $this
        }

        foreach ($subquery in @($Query | Where-Object { $_ })) {
            switch ($subquery) {
                { $_ -is [string] } {
                    $this.AddSubtreeItem($subquery, $folder, $null)
                    break
                }

                { $_ -is [pscustomobject] } {
                    foreach ($property in $_.PsObject.Properties) {
                        $doForEach = [MtpDevice]::NewClosure(
                            {
                                Param($MtpDevice)
                                $MtpDevice.Subtree($Parameters)
                            },
                            $property.Value `
                        )

                        $this.AddSubtreeItem(
                            $property.Name,
                            $folder,
                            $doForEach
                        )
                    }

                    break
                }

                default {
                    Write-Host "[$_]: Whoops."
                    break
                }
            }
        }

        return $this
    }

    static [MtpDevice[]]
    All([string] $PropertyName, [string[]] $Pattern) {
        $shell = New-Object -ComObject Shell.Application
        $fileSystem = $shell.NameSpace([MtpDevice]::NAMESPACE_THIS_PC_CODE)

        return $fileSystem.Items() |
            Where-Object { -not $_.IsFileSystem } |
            Where-Object { $_.$PropertyName -like "$Pattern*" } |
            ForEach-Object { [MtpDevice]::new($_) }
    }

    static [MtpDevice[]]
    All() {
        $shell = New-Object -ComObject Shell.Application
        $fileSystem = $shell.NameSpace([MtpDevice]::NAMESPACE_THIS_PC_CODE)

        return $fileSystem.Items() |
            Where-Object { -not $_.IsFileSystem } |
            ForEach-Object { [MtpDevice]::new($_) }
    }

    static [string[]]
    AvailableDeviceNames() {
        $shell = New-Object -ComObject Shell.Application
        $fileSystem = $shell.NameSpace([MtpDevice]::NAMESPACE_THIS_PC_CODE)

        return $fileSystem.Items() |
            Where-Object { -not $_.IsFileSystem } |
            ForEach-Object { $_.Name }
    }

    static [MtpDevice]
    Error() {
        return [MtpDevice]::new()
    }

    static [object]
    GetTree([object] $FileSystemCom) {
        if (-not $FileSystemCom) {
            return $null
        }

        switch ($FileSystemCom) {
            { $_ -is [string] } {
                return $FileSystemCom
            }

            default {
                $tree = [pscustomobject]@{}

                $FileSystemCom.
                PsObject.
                Properties |
                Where-Object {
                    $_.MemberType -eq 'NoteProperty'
                } |
                ForEach-Object {
                    $tree | Add-Member `
                        -MemberType 'NoteProperty' `
                        -Name $_.Name `
                        -Value $([MtpDevice]::GetTree($_.Value))
                }

                return $tree
            }
        }

        return $null
    }

    static [string[]]
    GetContainerPath([string] $DeviceName, [string] $PartialPath) {
        $separator = [MtpDevice]::PATH_SEPARATOR
        $shell = New-Object -ComObject Shell.Application

        $fileSystem = $shell.NameSpace([MtpDevice]::NAMESPACE_THIS_PC_CODE).Items() |
            Where-Object {
                $_.Name.ToLower() -eq $DeviceName.ToLower()
            } |
            ForEach-Object {
                $_.GetFolder
            }

        $parts = $PartialPath.Split($separator).Trim('"')
        $ptr = $fileSystem
        $treeSoFar = $parts | Select-Object -SkipLast 1

        foreach ($part in $treeSoFar) {
            $part = $part.ToLower()

            $ptr = $ptr.Items() |
                Where-Object {
                    $_.Name.ToLower() -in @($part, [MtpDevice]::ABBREVIATIONS[$part])
                } |
                ForEach-Object {
                    $_.GetFolder
                }
        }

        return $($ptr.Items() |
            Where-Object {
                $_.IsFolder
            } |
            ForEach-Object {
                $_.Name
            } |
            Where-Object {
                $_.ToLower() -like "$(($parts | Select-Object -Last 1).ToLower())*"
            } |
            ForEach-Object {
                $abbreviation = [MtpDevice]::PLEASE_ABBREVIATE[$_]

                if ($abbreviation) {
                    $abbreviation
                }
                else {
                    $_
                }
            } |
            Sort-Object |
            ForEach-Object {
                @(@($parts | Select-Object -SkipLast 1) + @($_)) -join $separator
            } |
            ForEach-Object {
                if ($_ -like "* *") { "`"$_`"" } else { $_ }
            })
    }

    [object]
    Tree() {
        return [MtpDevice]::GetTree($this)
    }

    [string]
    ToJson() {
        return $this.Tree() | ConvertTo-Json -Depth 100
    }

    [object[]]
    Items() {
        if ($null -eq $this.Com_) {
            return @()
        }

        return $this.Com_.GetFolder.Items() |
        ForEach-Object { $_ }
    }

    [object[]]
    Run([string] $Verb, $Destination) {
        if ($null -eq $this.Com_) {
            return @()
        }

        $ErrorActionPreference = 'Continue'

        return $(@($Destination) |
        ForEach-Object {
            $datetime = Get-Date -Format $this.DateTimeFormat_
            $folder = mkdir (Join-Path $_ $datetime)
            $shell = New-Object -ComObject Shell.Application
            $destCom = $shell.NameSpace($folder.FullName)

            [void] $destCom.
                ($Verb)($this.Com_, $this.ReadWriteOptions_)

            Get-Item $folder
        })
    }

    [object[]]
    Save($Destination) {
        return $this.Run('CopyHere', $Destination)
    }

    [object[]]
    Move($Destination) {
        return $this.Run('MoveHere', $Destination)
    }

    [object[]]
    Upload($Source) {
        if ($null -eq $this.Com_) {
            return @()
        }

        $ErrorActionPreference = 'Continue'

        return $(
            Get-Item $Source |
            ForEach-Object { $_.FullName } |
            ForEach-Object {
                $this.Com_.GetFolder.CopyHere($_, $this.ReadWriteOptions_)
                $this.Com_.GetFolder.Name
            }
        )
    }

    [object[]]
    Save() {
        return $this.Save((Get-Location))
    }

    [object[]]
    Move() {
        return $this.Move((Get-Location))
    }

    [object[]]
    Upload() {
        return $this.Move((Get-Location))
    }
}

function Get-MtpDeviceItem {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param(
        [Parameter(ParameterSetName = 'ByNameAndQuery')]
        [Parameter(ParameterSetName = 'ByNameAndPath')]
        [ArgumentCompleter({
            Param($A, $B, $C)

            $names = [MtpDevice]::AvailableDeviceNames()

            $suggest = $names |
                Where-Object { $_ -like "$C*" }

            $(if ($suggest) {
                $suggest
            }
            else {
                $names
            }) |
            ForEach-Object {
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

        [Parameter(ParameterSetName = 'ByTypeAndQuery')]
        [Parameter(ParameterSetName = 'ByTypeAndPath')]
        [ArgumentCompleter({
            Param($A, $B, $C)

            $shell = New-Object -ComObject Shell.Application
            $fileSystem = $shell.NameSpace([MtpDevice]::NAMESPACE_THIS_PC_CODE)

            $types = $fileSystem.Items() |
                Where-Object { -not $_.IsFileSystem } |
                ForEach-Object { $_.Type }

            $suggest = $devices |
                Where-Object { $_ -like "$C*" }

            $(if ($suggest) {
                $suggest
            }
            else {
                $types
            }) |
            ForEach-Object {
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

        [Parameter(ParameterSetName = 'ByNameAndQuery')]
        [Parameter(ParameterSetName = 'ByTypeAndQuery')]
        [string[]]
        $Query,

        [Parameter(ParameterSetName = 'ByNameAndPath')]
        [Parameter(ParameterSetName = 'ByTypeAndPath')]
        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )

            $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

            [MtpDevice]::GetContainerPath(
                $FakeBoundParameters['Name'],
                $WordToComplete
            ) |
            ForEach-Object {
                $CompletionResults.Add($_)
            }

            return $CompletionResults
        })]
        [string]
        $MtpPath
    )

    $devices = if ($PsCmdlet.ParameterSetName -eq 'All') {
        [MtpDevice]::All()
    }
    else {
        if ($Name) {
            [MtpDevice]::All('Name', $Name)
        }
        elseif ($Type) {
            [MtpDevice]::All('Type', $Type)
        }
    }

    $devices = $devices |
        Where-Object { $_ }

    if (-not $devices) {
        return [MtpDevice]::Error()
    }

    if ($Query) {
        foreach ($subquery in $Query) {
            $select = $subquery |
                ConvertFrom-Json -Depth 100

            $devices |
                ForEach-Object { $_.Subtree($select) }
        }
    }
    elseif ($MtpPath) {
        $devices |
            ForEach-Object { $_.MtpPath($MtpPath) }
    }
    else {
        $devices
    }
}

