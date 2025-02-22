class GrepWalk {
    [Microsoft.PowerShell.Commands.MatchInfo[]] $Capture
    [int] $Index

    GrepWalk([Microsoft.PowerShell.Commands.MatchInfo[]] $Capture) {
        $this.Capture = $Capture
        $this.Index = -1

        $this | Add-Member `
            -MemberType ScriptProperty `
            -Name Count `
            -Value { @($this.Capture).Count } `
            -TypeName int `
            -Force

        $this | Add-Member `
            -MemberType ScriptProperty `
            -Name Current `
            -Value {
                if ($this.ValidIndex()) {
                    @($this.Capture)[$this.Index].Path
                }
                else {
                    ''
                }
            } `
            -TypeName string `
            -Force
    }

    [string] ToString() {
        return $(if ($this.Any()) {
            @($this.Capture)[$this.Index].Path
        }
        else {
            ''
        })
    }

    [bool] Any([int] $Index) {
        return $Index -lt $this.Capture.Count
    }

    [bool] Any() {
        return $this.Any($this.Index)
    }

    [bool] ValidIndex([int] $Index) {
        return $Index -ge 0 -and $this.Any($Index)
    }

    [bool] ValidIndex() {
        return $this.ValidIndex($this.Index)
    }

    [void] Reset() {
        $this.Index = -1
    }

    [bool] Open() {
        if (-not $this.ValidIndex()) {
            return $false
        }

        $this.Capture[$this.Index] | Start-Edit
        return $true
    }

    [pscustomobject] Next() {
        $this.Index++
        $hasAny = $this.Open()

        return [pscustomobject]@{
            Any = $hasAny
            Remain = $this.Count - $this.Index - 1
            Next =
                if ($hasAny) {
                    @($this.Capture)[$this.Index].Path
                }
                else {
                    $null
                }
        }
    }

    [pscustomobject] NextChildItem() {
        if (-not $this.ValidIndex()) {
            return $null
        }

        $index = $this.Index
        $currentPath = @($this.Capture)[$index].Path

        while ($this.ValidIndex($index) -and @($this.Capture)[$index].Path -eq $currentPath) {
            $index = $index + 1
        }

        return $this.GoTo($index)
    }

    [pscustomobject] PrevChildItem() {
        if (-not $this.ValidIndex()) {
            return $null
        }

        $index = $this.Index
        $currentPath = @($this.Capture)[$index].Path

        while ($this.ValidIndex($index) -and @($this.Capture)[$index].Path -eq $currentPath) {
            $index = $index - 1
        }

        return $this.GoTo($index)
    }

    [Microsoft.PowerShell.Commands.MatchInfo[]] GoTo([int] $Index) {
        if (-not $this.ValidIndex($Index)) {
            return $null
        }

        $this.Index = $Index
        return $this.Capture[$this.Index]
    }

    [Microsoft.PowerShell.Commands.MatchInfo[]] GoBack() {
        return $this.GoTo($this.Index - 1)
    }

    [Microsoft.PowerShell.Commands.MatchInfo[]] GoNext() {
        return $this.GoTo($this.Index - 1)
    }
}

function ConvertTo-Walkable {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [Microsoft.PowerShell.Commands.MatchInfo[]]
        $InputObject = @()
    )

    Begin {
        $list = @()
    }

    Process {
        $list += @($InputObject)
    }

    End {
        return [GrepWalk]::new($list)
    }
}

New-Alias `
    -Name Walk `
    -Value ConvertTo-Walkable `
    -Scope Global `
    -Option ReadOnly `
    -Force

