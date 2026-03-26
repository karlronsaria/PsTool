enum YamlLexType {
    None
    NewLine
    Colon
    Symbol
    ListItem
    Indent
    End
}

class YamlScanner: System.Collections.IEnumerator {
    [YamlLexType] $LastLexType = [YamlLexType]::None
    [string] $Content
    [string] $Buffer
    [CharEnumerator] $Scanner
    [System.Collections.Generic.Queue[pscustomobject]] $Queue

    hidden [pscustomobject] $Current_ = $null

    YamlScanner([string[]] $Content) {
        $this.Content = $Content -join "`n"
        $this.Scanner = $this.Content.GetEnumerator()
        $this.Queue = [System.Collections.Generic.Queue[pscustomobject]]::new()
    }

    [object] get_Current() {
        return $this.Current_
    }

    [void] Reset() {
        $this.LastLexType = [YamlLexType]::None
        $this.Buffer = ''
        $this.Scanner.Reset()
        $this.Queue.Clear()
    }

    [bool] MoveNext() {
        $this.Current_ = $this.Next()
        return $null -ne $this.Current_ -and $this.Current_.Success
    }

    hidden [pscustomobject]
    ScanIndent() {
        $length = 1

        while ($this.Scanner.MoveNext() -and $this.Scanner.Current -eq ' ') {
            $length++
        }

        $this.LastLexType = [YamlLexType]::Indent

        return [pscustomobject]@{
            Success = $true
            LexType = $this.LastLexType
            Length = $length
        }
    }

    hidden [pscustomobject]
    ScanListItem() {
        while ($this.Scanner.MoveNext() -and $this.Scanner.Current -eq ' ') {}

        $this.LastLexType = [YamlLexType]::ListItem

        return [pscustomobject]@{
            Success = $true
            LexType = $this.LastLexType
        }
    }

    hidden [pscustomobject]
    ScanQuote() {
        $builder = [System.Text.StringBuilder]::new()
        $next = $this.Scanner.MoveNext()

        while ($next -and $this.Scanner.Current -ne '"') {
            $builder.Append($this.Scanner.Current)
            $next = $this.Scanner.MoveNext()
        }

        if (-not $next) {
            return [pscustomobject]@{
                Success = $false
                LexType = [YamlLexType]::End
            }
        }

        $value = $builder.ToString().Trim()
        $this.LastLexType = [YamlLexType]::Symbol

        return [pscustomobject]@{
            Success = $true
            LexType = $this.LastLexType
            Value = $value
        }
    }

    [pscustomobject]
    Next() {
        if ($this.Queue.Count -gt 0) {
            $token = $this.Queue.Dequeue()
            $this.LastLexType = $token.LexType
            return $token
        }

        $next = $true
        $current = $this.Buffer
        $this.Buffer = ''

        if ([string]::IsNullOrEmpty($current)) {
            $next = $this.Scanner.MoveNext()
            $current = $this.Scanner.Current
        }

        if ($this.LastLexType -in @(
            [YamlLexType]::None,
            [YamlLexType]::NewLine,
            [YamlLexType]::Indent
        )) {
            if (-not $next) {
                return [pscustomobject]@{
                    Success = $false
                    LexType = [YamlLexType]::End
                }
            }

            if ($current -eq ' ') {
                $token = $this.ScanIndent()
                $this.Buffer = $this.Scanner.Current
                return $token
            }

            if ($current -eq '-') {
                $token = $this.ScanListItem()
                $this.Buffer = $this.Scanner.Current
                return $token
            }
        }

        if ($current -eq '"') {
            return $this.ScanQuote()
        }

        $builder = [System.Text.StringBuilder]::new()

        while ($next) {
            if ($current -eq ':') {
                if (-not $this.Scanner.MoveNext()) {
                    $this.Queue.Enqueue(
                        [pscustomobject]@{
                            Success = $true
                            LexType = [YamlLexType]::Colon
                        }
                    )

                    $this.Queue.Enqueue(
                        [pscustomobject]@{
                            Success = $false
                            LexType = [YamlLexType]::End
                        }
                    )

                    $this.LastLexType = [YamlLexType]::Symbol

                    return [pscustomobject]@{
                        Success = $true
                        LexType = $this.LastLexType
                        Value = $builder.ToString().Trim()
                    }
                }

                $current = $this.Scanner.Current

                if ($current -eq "`n") {
                    $this.Queue.Enqueue(
                        [pscustomobject]@{
                            Success = $true
                            LexType = [YamlLexType]::Colon
                        }
                    )

                    $this.Queue.Enqueue(
                        [pscustomobject]@{
                            Success = $true
                            LexType = [YamlLexType]::NewLine
                        }
                    )

                    $this.LastLexType = [YamlLexType]::Symbol

                    return [pscustomobject]@{
                        Success = $true
                        LexType = $this.LastLexType
                        Value = $builder.ToString().Trim()
                    }
                }

                if ($current -eq ' ') {
                    $this.Queue.Enqueue(
                        [pscustomobject]@{
                            Success = $true
                            LexType = [YamlLexType]::Colon
                        }
                    )

                    $this.LastLexType = [YamlLexType]::Symbol

                    return [pscustomobject]@{
                        Success = $true
                        LexType = $this.LastLexType
                        Value = $builder.ToString().Trim()
                    }
                }

                $builder.Append(':')
            }

            if ($current -eq "`n") {
                $this.Queue.Enqueue(
                    [pscustomobject]@{
                        Success = $true
                        LexType = [YamlLexType]::NewLine
                    }
                )

                if ($builder.Length -gt 0) {
                    $this.LastLexType = [YamlLexType]::Symbol

                    return [pscustomobject]@{
                        Success = $true
                        LexType = $this.LastLexType
                        Value = $builder.ToString().Trim()
                    }
                }
                else {
                    $value = $this.Queue.Dequeue()
                    $this.LastLexType = $value.LexType
                    return $value
                }
            }

            $builder.Append($current)
            $next = $this.Scanner.MoveNext()
            $current = $this.Scanner.Current
        }

        if ($builder.Length -gt 0) {
            $this.LastLexType = [YamlLexType]::Symbol

            return [pscustomobject]@{
                Success = $true
                LexType = $this.LastLexType
                Value = $builder.ToString().Trim()
            }
        }

        return [pscustomobject]@{
            Success = $false
            LexType = [YamlLexType]::End
        }
    }
}

function ConvertFrom-Yaml {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [string[]]
        $InputObject
    )

    Begin {
        $list = @()

        function ConvertTo-Table {
            Param(
                [Parameter(ValueFromPipeline = $true)]
                [pscustomobject]
                $InputObject
            )

            Begin {
                $level = 0
                $listItem = $false
                $list = @()
                $maxLevel = 0
            }

            Process {
                if (-not $InputObject.Success) {
                    return
                }

                switch ([YamlLexType]$InputObject.LexType) {
                    { $_ -eq [YamlLexType]::Colon } {
                        $level++
                        break
                    }

                    { $_ -eq [YamlLexType]::Indent } {
                        $level = $InputObject.Length
                        break
                    }

                    { $_ -eq [YamlLexType]::ListItem } {
                        $listItem = $true
                        break
                    }

                    { $_ -eq [YamlLexType]::Symbol } {
                        $list += @([pscustomobject]@{
                            Level = $level
                            RowType =
                                if ($listItem) {
                                    [YamlLexType]::ListItem
                                }
                                else {
                                    [YamlLexType]::Symbol
                                }
                            Value = $InputObject.Value
                        })

                        if ($level -gt $maxLevel) {
                            $maxLevel = $level
                        }

                        $listItem = $false
                        break
                    }
                }
            }

            End {
                [pscustomobject]@{
                    MaxLevel = $maxLevel
                    Table = $list
                }
            }
        }

        function Test-EmptyObject {
            Param(
                [PsCustomObject]
                $InputObject
            )

            return 0 -eq @($InputObject.PsObject.Properties).Count
        }

        function Add-Property {
            Param(
                $InputObject,

                [String]
                $Name,

                $Value,

                [Switch]
                $Overwrite,

                [Switch]
                $Table
            )

            $property = $InputObject.PsObject.Properties | where {
                $_.Name -eq $Name
            }

            if ($null -eq $property) {
                $InputObject | Add-Member `
                    -MemberType NoteProperty `
                    -Name $Name `
                    -Value $Value

                return
            }

            if (@($property.Value).Count -eq 1) {
                $property.Value = @($property.Value)
            }

            if ((Test-EmptyObject $property.Value[-1])) {
                $property.Value[-1] = @($Value)
            }
            else {
                $property.Value += @($Value)
            }
        }

        <#
        .SYNOPSIS
        f: P(key, value) -> key -> value
        #>
        function Get-NoteProperty {
            Param(
                [Parameter(
                    ValueFromPipeline = $true,
                    Position = 0
                )]
                [PsCustomObject]
                $InputObject,

                [String]
                $PropertyName,

                $Default
            )

            $properties = $InputObject.PsObject.Properties `
                | where { 'NoteProperty' -eq $_.MemberType }

            if ([String]::IsNullOrEmpty($PropertyName)) {
                return $properties
            }

            try {
                return $(if ($null -eq $properties -or @($properties).Count -eq 0) {
                    [PsCustomObject]@{
                        Success = $false
                        Name = $PropertyName
                        Value = $null
                    }
                } elseif ($PropertyName -in $properties.Name) {
                    [PsCustomObject]@{
                        Success = $true
                        Name = $PropertyName
                        Value = $InputObject.$PropertyName
                    }
                } elseif ($null -ne $Default) {
                    [PsCustomObject]@{
                        Success = $false
                        Name = $PropertyName
                        Value = $Default.$PropertyName
                    }
                } else {
                    [PsCustomObject]@{
                        Success = $false
                        Name = $PropertyName
                        Value = $null
                    }
                })
            }
            catch {
                return [PsCustomObject]@{
                    Success = $false
                    Name = $PropertyName
                    Value = $null
                }
            }

            return [PsCustomObject]@{
                Success = $false
                Name = $PropertyName
                Value = $null
            }
        }

        function Test-IsLeaf {
            Param(
                [PsCustomObject]
                $InputObject
            )

            $props = Get-NoteProperty $InputObject

            return @($props).Count -eq 1 -and $(
                    $value = @($props)[0].Value;
                    $value -is [PsCustomObject]
                ) -and
                $null -eq (Get-NoteProperty $value)
        }

        function Convert-LeafToString {
            Param(
                [PsCustomObject]
                $InputObject
            )

            foreach ($prop in (Get-NoteProperty $InputObject)) {
                $value = $prop.Value

                if (Test-IsLeaf $value) {
                    $InputObject.($prop.Name) =
                        @(Get-NoteProperty $value)[0].Name
                }
                else {
                    $value | foreach {
                        Convert-LeafToString $_
                    }
                }
            }
        }

        function ConvertTo-Tree {
            Param(
                [Parameter(ValueFromPipeline = $true)]
                [pscustomobject]
                $InputObject,

                [int]
                $MaxLevel
            )

            Begin {
                $stack = @($null) * ($MaxLevel + 2)
                $stack[0] = [PsCustomObject]@{}
                $prevLevel = 0
                $level = 0
                # $str = ''

            }

            Process {
                $level = $InputObject.Level + 1

                while ($prevLevel -gt $level) {
                    $stack[$prevLevel] = $null
                    $prevLevel--
                }

                $content = $InputObject.Value
                $stack[$level] = [PsCustomObject]@{}
                $nextIndex = $level - 1

                while ($null -eq $stack[$nextIndex]) {
                    $nextIndex--
                }

                Add-Property `
                    -InputObject $stack[$nextIndex] `
                    -Name $content `
                    -Value $stack[$level]

                $prevLevel = $level
            }

            End {
                Convert-LeafToString $stack[0]
                return $stack[0]
            }
        }
    }

    Process {
        $list += @($InputObject)
    }

    End {
        $scan = [YamlScanner]::new($list) |
            ForEach-Object { $_ } |
            ConvertTo-Table

        $scan.Table |
            ConvertTo-Tree `
                -MaxLevel $scan.MaxLevel
    }
}

