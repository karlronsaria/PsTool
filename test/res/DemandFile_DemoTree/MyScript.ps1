Get-DemoPathFunctionNameScramble {
  dir *.ps1 -Recurse |
  foreach {
    $file = get-item $_
    $cat = gc $file

    $sed = foreach ($line in $cat) {
      $capture = [Regex]::Match($line, "(?<=^function\s+)\S+(?=\s*(\{|$))")

      if (-not $capture.Success) {
        $line
        continue
      }

      $value = $capture.Value
      $split = $value.Split("-")

      $scramble = ($split |
      foreach {
        $enum = $_ -split ""
        "$("$($enum[1])".ToUpper())$(($enum[($enum.Count - 1) .. 2] -join '').ToLower())"
      }) -join "-"

      $line.Replace(
        $value,
        "__Demo__$scramble"
      )
    }

    Set-Content -Value $sed -Path $file -Encoding utf8
  }
}

