class SyntaxStack {
    hidden [array] $Stack
    hidden [int] $PrevLevel
    hidden [int] $Level

    SyntaxStack([int] $Size) {
        $this.Stack = @($null) * ($Size + 1)
        $this.Stack[0] = [PsCustomObject]@{}
        $this.PrevLevel = 0
        $this.Level = 0
    }
    
    [SyntaxStack]
    Add([int] $Level, [object] $Content, [scriptblock] $Where) {
        $this.Level = $Level + 1

        if ($this.Level -ge @($this.Stack).Count) {
            $this.Stack += @(@($null) * (2 * ($this.Level - @($this.Stack).Count + 1)))
        }

        while ($this.PrevLevel -gt $this.Level) {
            $this.Stack[$this.PrevLevel] = $null
            $this.PrevLevel--
        }

        $this.Stack[$this.Level] = [PsCustomObject]@{}
        $nextIndex = $this.Level - 1

        while ($null -eq $this.Stack[$nextIndex]) {
            $nextIndex--
        }

        if ($Where.Invoke($Level, $Content)) {
            [SyntaxStack]::AddProperty(
                $this.Stack[$nextIndex],
                $Content,
                $this.Stack[$this.Level]
            )
        }

        $this.PrevLevel = $this.Level
        return $this
    }

    [SyntaxStack]
    Add([int] $Level, [object] $Content) {
        $this.Level = $Level + 1

        if ($this.Level -ge @($this.Stack).Count) {
            $this.Stack += @(@($null) * (2 * ($this.Level - @($this.Stack).Count + 1)))
        }

        while ($this.PrevLevel -gt $this.Level) {
            $this.Stack[$this.PrevLevel] = $null
            $this.PrevLevel--
        }

        $this.Stack[$this.Level] = [PsCustomObject]@{}
        $nextIndex = $this.Level - 1

        while ($null -eq $this.Stack[$nextIndex]) {
            $nextIndex--
        }

        [SyntaxStack]::AddProperty(
            $this.Stack[$nextIndex],
            $Content,
            $this.Stack[$this.Level]
        )

        $this.PrevLevel = $this.Level
        return $this
    }

    [pscustomobject]
    ToTree() {
        [SyntaxStack]::ConvertLeafToString($this.Stack[0])
        return $this.Stack[0]
    }

    static [bool]
    IsEmptyObject([object] $InputObject) {
        return 0 -eq @($InputObject.PsObject.Properties).Count
    }

    static [bool]
    IsLeaf([object] $InputObject) {
        $props = $InputObject.PsObject.Properties |
            Where-Object { 'NoteProperty' -eq $_.MemberType }

        return @($props).Count -eq 1 -and $(
            $(
                $value = @($props)[0].Value;
                $value -is [PsCustomObject]
            ) -and
            $null -eq ($value.PsObject.Properties |
                Where-Object { 'NoteProperty' -eq $_.MemberType })
        )
    }

    static [void]
    AddProperty(
        [object] $InputObject,
        [string] $Name,
        [object] $Value
    ) {
        $property = $InputObject.PsObject.Properties |
        Where-Object {
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

        if (([SyntaxStack]::IsEmptyObject($property.Value[-1]))) {
            $property.Value[-1] = @($Value)
        }
        else {
            $property.Value += @($Value)
        }
    }

    static [void]
    ConvertLeafToString([object] $InputObject) {
        $props = $InputObject.PsObject.Properties |
            Where-Object { 'NoteProperty' -eq $_.MemberType }

        foreach ($prop in $props) {
            $value = $prop.Value

            if ([SyntaxStack]::IsLeaf($value)) {
                $valueProps = $value.PsObject.Properties |
                    Where-Object { 'NoteProperty' -eq $_.MemberType }

                $InputObject.($prop.Name) =
                    @($valueProps)[0].Name
            }
            else {
                $value | ForEach-Object {
                    [SyntaxStack]::ConvertLeafToString($_)
                }
            }
        }
    }
}

