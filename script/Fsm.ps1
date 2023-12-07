function Get-FiniteStateMachine {
    Param(
        [String]
        $Pattern,

        [Hashtable]
        $Machine
    )

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
