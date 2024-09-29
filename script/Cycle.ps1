class Cycleable: System.Collections.ICollection {
    hidden [System.Collections.IEnumerable] $Sequence = @()

    Cycleable([System.Collections.IEnumerable] $Sequence) {
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
        return [System.Collections.IEnumerator] [Cycle]::new($this.Sequence)
    }
}

class Cycle: System.Collections.IEnumerator {
    hidden [Object[]] $Sequence = @()
    hidden [Int] $Index = -1

    hidden [ScriptBlock] $MyNextMethod = {
        Param([Cycle] $Cycle)
        return $null
    }

    hidden [ScriptBlock] $ExpectedNextMethod = {
        Param([Cycle] $Cycle)
        $Cycle.Index = $Cycle.NextIndex()
        return $Cycle.Current
    }

    [Int] NextIndex() {
        return $(
            if ($this.Index -eq $this.Sequence.Count - 1) {
                0
            }
            else {
                $this.Index + 1
            }
        )
    }

    Cycle([Object] $Sequence) {
        if ($null -ne $Sequence -and $Sequence.Count -gt 0) {
            $this.Sequence = $Sequence
            $this.MyNextMethod = [Cycle]::ExpectedNextMethod
        }
    }

    [Object] get_Current() {
        return $this.Sequence[$this.Index]
    }

    [Object] Next() {
        return $(
            if ($this.Any()) {
                $this.Index = $this.NextIndex()
                $this.Current
            }
            else {
                $null
            }
        )
    }

    [Int] Count() {
        return $this.Sequence.Count
    }

    [Boolean] Any() {
        return $this.Sequence.Count -ne 0
    }

    [void] Reset() {
        $this.Index = -1
    }

    [Boolean] MoveNext() {
        [void] $this.Next()
        return $this.Any()
    }
}

function ConvertTo-Cycle {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [Object[]]
        $InputObject = @()
    )

    Begin {
        $list = @()
    }

    Process {
        $list += @($InputObject)
    }

    End {
        return [Cycle]::new($list)
    }
}

New-Alias -Name 'Cycle' -Value 'ConvertTo-Cycle' -Force

function Get-Zip {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [Object[]]
        $First = @(),

        [Parameter(Position = 1)]
        [Object[]]
        $Second = @()
    )

    Begin {
        $list = @()
    }

    Process {
        $list += @($First)
    }

    End {
        $a = $list.GetEnumerator()
        $b = $Second.GetEnumerator()

        $a_any = $a.MoveNext()
        $b_any = $b.MoveNext()

        while ($a_any -or $b_any) {
            [PsCustomObject]@{
                0 = $(if ($a_any) { $a.Current } else { $null })
                1 = $(if ($b_any) { $b.Current } else { $null })
            }

            $a_any = $a.MoveNext()
            $b_any = $b.MoveNext()
        }
    }
}

New-Alias -Name 'Zip' -Value 'Get-Zip' -Force

function Write-IdleProgress {
    [CmdletBinding(DefaultParameterSetName = "SpinnerText")]
    Param(
        [Parameter(ParameterSetName = "MarqueeText")]
        [String]
        $MarqueeText,

        [Parameter(ParameterSetName = "SpinnerText")]
        [String[]]
        $SpinnerText = @(" -", " \", " |", " /"), # todo: @(" ⡏", " ⢹", " ⣸", " ⣇"),

        [Int]
        $Id,

        [String]
        $Activity,

        [Int]
        $Milliseconds,

        [Int]
        $Red = -1,

        [Int]
        $Green = -1,

        [Int]
        $Blue = -1
    )

    function Get-ActualColor {
        Param(
            [Int]
            $Red = -1,

            [Int]
            $Green = -1,

            [Int]
            $Blue = -1
        )

        if ($Red -eq -1 -and $Green -eq -1 -and $Blue -eq -1) {
            $Red = 255
            $Green = 255
            $Blue = 255
        }
        else {
            if ($Red -eq -1) {
                $Red = 0
            }

            if ($Green -eq -1) {
                $Green = 0
            }

            if ($Blue -eq -1) {
                $Blue = 0
            }
        }

        [PsCustomObject]@{
            Red = $Red
            Green = $Green
            Blue = $Blue
        }
    }

    function Get-ActualLength {
        Param(
            [String]
            $Activity,

            [Int]
            $Red,

            [Int]
            $Green,

            [Int]
            $Blue
        )

        return $host.UI.RawUI.WindowSize.Width -
            "$Activity$Red$Green$Blue".Length - 19
    }

    function ConvertTo-ColorText {
        Param(
            [String]
            $InputObject,

            [Int]
            $Red = -1,

            [Int]
            $Green = -1,

            [Int]
            $Blue = -1
        )

        return `
        "$([char]27)[38;2;$($Red);$($Green);$($Blue)m$InputObject$([char]27)[0m"
    }

    $color = Get-ActualColor `
        -Red $Red `
        -Green $Green `
        -Blue $Blue

    $length = Get-ActualLength `
        -Activity $Activity `
        -Red $color.Red `
        -Green $color.Green `
        -Blue $color.Blue

    if ($PsCmdlet.ParameterSetName -eq "MarqueeText") {
        $SpinnerText =
            0 .. ($MarqueeText.Length - 1) |
            foreach {
                if ($_ + $length -ge $MarqueeText.Length) {
                    # # (karlr 2024_09_29)
                    # "$($MarqueeText.Substring($_))$($MarqueeText.Substring(0, $ddength - ($MarqueeText.Length - $_)))"
                    "$($MarqueeText.Substring($_))$($MarqueeText.Substring(0, $_))"
                }
                else {
                    $MarqueeText.Substring($_, $length)
                }
            }
    }

    $SpinnerText | cycle | foreach {
        $colorText = ConvertTo-ColorText `
            -InputObject $_ `
            -Red $color.Red `
            -Green $color.Green `
            -Blue $color.Blue

        Write-Progress `
            -Id $Id `
            -Activity $Activity `
            -Status $colorText `
            -PercentComplete 0

        Start-Sleep `
            -Milliseconds $Milliseconds
    }
}

