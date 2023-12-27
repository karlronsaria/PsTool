<#
Tags: eme fsm finite state machine pattern match
#>

<#
Tags: nti closure
#>
function __Demo__Nwe-Cerusol {
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
Tags: sep type
#>
function __Demo__Gte-Fenihcamepytms {
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
Tags: hir string
#>
function __Demo__Gte-Fenihcamgnirtsms {
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
            $_.Name -ne 0 -and
            $_.Success
        }).
        Name
    ].
    Invoke($Arguments)
}
}
}
