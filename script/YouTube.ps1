function ConvertFrom-YouTubeRedirect {
    Param(
        [Parameter(
            ValueFromPipeline = $true
        )]
        [string[]]
        $InputObject
    )

    Process {
        foreach ($subobject in @(@($InputObject) | where { $_ })) {
            $subobject |
                foreach { $_ -replace "^.*&q=", "" } |
                foreach { $_ -replace "&v=.*$", "" } |
                foreach { $_.Replace("%3A", ":") } |
                foreach { $_.Replace("%2F", "/") }
        }
    }
}

