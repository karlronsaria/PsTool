function Select-CaseInsensitive {
    $Input | select -Unique -CaseInsensitive
}
