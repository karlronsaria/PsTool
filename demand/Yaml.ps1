. "$PsScriptRoot/../lib/SyntaxStack.ps1"

enum YamlLexType {
    None
    NewLine
    Colon
    Symbol
    ListItem
    Indent
    End
}

class Yaml: System.Collections.ICollection {
    hidden [System.Collections.IEnumerable] $Sequence = @()

    Yaml([System.Collections.IEnumerable] $Sequence) {
        $this.Sequence = $Sequence
    }

    [int] get_Count() {
        return $this.Sequence.Count
    }

    [Boolean] get_IsSynchronized() {
        return $true
    }

    [Object] get_SyncRoot() {
        return $this
    }

    [void] CopyTo([Array] $Array, [Int] $Index) {
        while ($Index -lt $Array.Count -and $Index -lt $this.Sequence.Count) {
            $Array[$Index] = $this.Sequence[$Index]
            $Index++
        }
    }

    [System.Collections.IEnumerator] GetEnumerator() {
        return [System.Collections.IEnumerator] [YamlRowEnumerator]::new($this.Sequence)
    }
}

class YamlRowEnumerator: System.Collections.IEnumerator {
    hidden [int] $Level = 0
    hidden [bool] $ListItem = $false
    hidden [YamlTokenEnumerator] $Scanner
    hidden [pscustomobject] $Current_ = $null

    YamlRowEnumerator([string[]] $Content) {
        $this.Scanner = [YamlTokenEnumerator]::new($Content)
    }

    YamlRowEnumerator([System.CharEnumerator] $Scanner) {
        $this.Scanner = [YamlTokenEnumerator]::new($Scanner)
    }

    YamlRowEnumerator([YamlTokenEnumerator] $Scanner) {
        $this.Scanner = $Scanner
    }

    [object] get_Current() {
        return $this.Current_
    }

    [void] Reset() {
        $this.Scanner.Reset()
        $this.Level = 0
        $this.ListItem = $false
    }

    [bool] MoveNext() {
        $result = 0

        while ($result -eq 0) {
            $result = $this.NextRow()
        }

        return $result -ne -1
    }

    [int] NextRow() {
        if (-not $this.Scanner.MoveNext()) {
            $this.Current_ = $null
            return -1
        }

        $InputObject = $this.Scanner.Current

        switch ([YamlLexType]$InputObject.LexType) {
            { $_ -eq [YamlLexType]::Colon } {
                $this.Current_ = $null
                $this.Level++
                return 0
            }

            { $_ -eq [YamlLexType]::Indent } {
                $this.Current_ = $null
                $this.Level = $InputObject.Length
                return 0
            }

            { $_ -eq [YamlLexType]::ListItem } {
                $this.Current_ = $null
                $this.ListItem = $true
                return 0
            }

            { $_ -eq [YamlLexType]::Symbol } {
                $this.Current_ =
                    [pscustomobject]@{
                        Level = $this.Level
                        RowType =
                            if ($this.ListItem) {
                                [YamlLexType]::ListItem
                            }
                            else {
                                [YamlLexType]::Symbol
                            }
                        Content = $InputObject.Content
                    }

                $this.ListItem = $false
                return 1
            }
        }

        return 0
    }
}

class YamlTokenEnumerator: System.Collections.IEnumerator {
    hidden [YamlLexType] $LastLexType = [YamlLexType]::None
    hidden [char] $Buffer
    hidden [System.CharEnumerator] $Scanner
    hidden [System.Collections.Generic.Queue[pscustomobject]] $Queue
    hidden [pscustomobject] $Current_ = $null

    YamlTokenEnumerator([string[]] $Content) {
        $str = $Content -join "`n"
        $this.Scanner = $str.GetEnumerator()
        $this.Queue = [System.Collections.Generic.Queue[pscustomobject]]::new()
    }

    YamlTokenEnumerator([System.CharEnumerator] $Scanner) {
        $this.Scanner = $Scanner
        $this.Queue = [System.Collections.Generic.Queue[pscustomobject]]::new()
    }

    [object] get_Current() {
        return $this.Current_
    }

    [void] Reset() {
        $this.LastLexType = [YamlLexType]::None
        $this.Buffer = [char]0
        $this.Scanner.Reset()
        $this.Queue.Clear()
    }

    [bool] MoveNext() {
        $this.Current_ = $this.NextToken()
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
            Content = $value
        }
    }

    [pscustomobject]
    NextToken() {
        if ($this.Queue.Count -gt 0) {
            $token = $this.Queue.Dequeue()
            $this.LastLexType = $token.LexType
            return $token
        }

        $next = $true
        $current = $this.Buffer
        $this.Buffer = [char]0

        if ($null -eq $current -or [char]0 -eq $current) {
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
                # Negative scan
                $token = $this.ScanIndent()
                $this.Buffer = $this.Scanner.Current
                return $token
            }

            if ($current -eq '-') {
                # Negative scan
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
                        Content = $builder.ToString().Trim()
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
                        Content = $builder.ToString().Trim()
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
                        Content = $builder.ToString().Trim()
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
                        Content = $builder.ToString().Trim()
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
                Content = $builder.ToString().Trim()
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
    }

    Process {
        $list += @($InputObject)
    }

    End {
        $stack = [SyntaxStack]::new([math]::Log($list.Count))

        [Yaml]::new($list) |
            ForEach-Object {
                [void] $stack.Add($_.Level, $_.Content)
            }

        return $stack.ToTree()
    }
}

