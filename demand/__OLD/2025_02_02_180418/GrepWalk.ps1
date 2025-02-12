class Walkable: System.Collections.ICollection {
    hidden [System.Collections.IEnumerable] $Sequence = @()

    Walkable([System.Collections.IEnumerable] $Sequence) {
        $this.Sequence = $Sequence
    }

    [Int] get_Count() {
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
            [void] $Index++
        }
    }

    [System.Collections.IEnumerator] GetEnumerator() {
        return [System.Collections.IEnumerator] [GrepWalk]::new($this.Sequence)
    }
}

<#
.DESCRIPTION
Tags: grep walk sls select-string enumerator
#>
class GrepWalk { # : System.Collections.IEnumerator {
    hidden [Microsoft.PowerShell.Commands.MatchInfo[]] $Capture = @()
    hidden [int] $Index = -1

    GrepWalk([Microsoft.PowerShell.Commands.MatchInfo[]] $Capture) {
        if ($null -ne $Capture -and @($Capture).Count -gt 0) {
            $this.Capture = $Capture
            $this.Index = -1
        }
    }

    [object] get_Current() {
        return $this.Capture[$this.Index]
    }

    [int] get_Count() {
        return @($this.Capture).Count
    }

    [bool] get_OpenItem() {
        return $this.Open()
    }

    [bool] get_NextItem() {
        return $this.MoveNext()
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

    [bool] Open() {
        if (-not $this.ValidIndex()) {
            return $false
        }

        $this.Capture[$this.Index] | Start-Edit
        return $true
    }

    [void] Reset() {
        $this.Index = -1
    }

    [bool] MoveNext() {
        $this.Index++
        return $this.Open()
    }

    [Microsoft.PowerShell.Commands.MatchInfo[]] GoTo([int] $Index) {
        if ($this.ValidIndex($Index)) {
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

