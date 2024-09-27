<#
Tags: fsm finite state machine pattern match
#>

<#
.DESCRIPTION
Tags: closure
#>
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

<#
.DESCRIPTION
Tags: type
#>
function Get-FsmTypeMachine {
    Param(
        [Hashtable]
        $Machine
    )

    return New-Closure `
        -Parameters ([PsCustomObject]@{
            Machine = $Machine
        }) `
        -ScriptBlock `
{
Param(
    [Parameter(
        ValueFromPipeline = $true,
        Position = 0
    )]
    [Object[]]
    $InputObject,

    [Object[]]
    $Arguments
)

foreach ($item in $InputObject) {
    $Parameters.Machine[
        $item.GetType()
    ].
    Invoke($Arguments)
}
}
}

<#
.DESCRIPTION
Tags: string
#>
function Get-FsmStringMachine {
    Param(
        [String]
        $Pattern,

        [Hashtable]
        $Machine
    )

    return New-Closure `
        -Parameters ([PsCustomObject]@{
            Machine = $Machine
            Pattern = $Pattern
        }) `
        -ScriptBlock `
{
Param(
    [Parameter(
        ValueFromPipeline = $true,
        Position = 0
    )]
    [String[]]
    $InputObject,

    [Object[]]
    $Arguments
)

foreach ($item in $InputObject) {
    $Parameters.Machine[
        ([Regex]::Match($item, $Parameters.Pattern).
        Groups |
        where {
            $_.Success -and
            $_.Name -notmatch '^\d$'
        }).
        Name
    ].
    Invoke($Arguments)
}
}
}
