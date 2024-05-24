function Select-CaseInsensitive {
    Begin {
        $list = @()
    }

    Process {
        $list += @($Input.ToLower())
    }

    End {
        $list | select -Unique
    }
}
