function ConvertTo-Mock {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    Begin {
        $mock = "estuansinteriusiravehementisephiroth".GetEnumerator()
        $list = @()
    }

    Process {
        $list += @($InputObject)
    }

    End {
        ($list |
        Out-String |
        ForEach-Object {
            $_.GetEnumerator()
        } |
        ForEach-Object {
            if (-not [char]::IsLetter($_)) {
                $_
            }
            else {
                if (-not $mock.MoveNext()) {
                    $mock.Reset()
                }

                if ([char]::IsUpper($_)) {
                    [char]::ToUpper($mock.Current)
                }
                else {
                    $mock.Current
                }
            }
        }) -join ""
    }
}

