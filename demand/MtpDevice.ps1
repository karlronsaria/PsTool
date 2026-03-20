<#
.DESCRIPTION
Tags: MTP, connected, device
#>

class MtpDevice {
    static [int] $NAMESPACE_THIS_PC_CODE = 17
    static [int] $FILESYSTEM_DO_NOT_PROMPT = 16
    static [int] $DEFAULT_DELAY_MS = 500
    static [string] $DEFAULT_DATETIME_FORMAT = 'yyyy-MM-dd-HHmmss' # Uses DateTimeFormat

    static [hashtable] $ABBREVIATIONS = @{
        'int' = 'Internal storage'
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
                    $items = $folder.Items() |
                        Where-Object {
                            $lowerquery = $subquery.ToLower()
                            $_.Name.ToLower() -in @($lowerquery, [MtpDevice]::ABBREVIATIONS[$lowerquery])
                        } |
                        Where-Object { $_ }

                    if (-not $items) {
                        try {
                            $folder.NewFolder($subquery)
                            Start-Sleep -Milliseconds $this.DelayMs_

                            $items = @(
                                $folder.Items() |
                                Where-Object {
                                    $lowerquery = $subquery.ToLower()
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

                        $this | Add-Member `
                            -MemberType NoteProperty `
                            -Name $item.Name `
                            -Value $value
                    }

                    break
                }

                { $_ -is [pscustomobject] } {
                    foreach ($property in $_.PsObject.Properties) {
                        $items = $folder.Items() |
                            Where-Object {
                                $lowerquery = $property.Name.ToLower()
                                $_.Name.ToLower() -in @($lowerquery, [MtpDevice]::ABBREVIATIONS[$lowerquery])
                            } |
                            Where-Object { $_ }

                        if (-not $items) {
                            try {
                                $folder.NewFolder($property.Name)
                                Start-Sleep -Milliseconds $this.DelayMs_

                                $items = @(
                                    $folder.Items() |
                                    Where-Object {
                                        $lowerquery = $property.Name.ToLower()
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

                            $this | Add-Member `
                                -MemberType NoteProperty `
                                -Name $item.Name `
                                -Value $value

                            $value.Subtree($property.Value)
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
        [Parameter(ParameterSetName = 'Name')]
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

        [Parameter(ParameterSetName = 'Type')]
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

        [string[]]
        $Query
    )

    $filterBy = $PsCmdlet.ParameterSetName

    $devices = if ($filterBy -ne 'All') {
        [MtpDevice]::All()
    }
    else {
        [MtpDevice]::All($filterBy, $PsBoundParameters[$filterBy].Value)
    }

    $devices = $devices |
        Where-Object { $_ }
        
    if (-not $devices) {
        return [MtpDevice]::Error()
    }

    if (-not $Query) {
        return $devices
    }

    foreach ($subquery in $Query) {
        $select = $subquery |
            ConvertFrom-Json -Depth 100

        $devices |
            ForEach-Object { $_.Subtree($select) }
    }
}

