# # todo
# - [ ] AutoSize
function __Demo__Ftamro-Melbatnwodkra {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    Begin {
        $firstRow = $true
    }

    Process {
        if ($firstRow) {
            $firstRow = $false

            $props = $InputObject.PsObject.Properties
            $row = '|'

            foreach ($prop in $props) {
                $row += " $($prop.Name) |"
            }

            Write-Output $row
            $row = '|'

            foreach ($prop in $props) {
                $row += "-$('-' * $prop.Name.Length)-|"
            }

            Write-Output $row
        }

        $row = '|'

        foreach ($prop in $props) {
            $row += " $($InputObject.($prop.Name)) |"
        }

        Write-Output $row
    }
}
