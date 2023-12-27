function New-Mock_Get_DemandScript {
  Param(
    [Switch]
    $Force
  )

  $depth = 8

  [PsCustomObject]@{
    MaxDepth = $depth
    Expect = [PsCustomObject]@{
      Query = @(
        $(
          $run = 'Get-DemandScript -All -Directory "$PsScriptRoot\res\DemandFile_DemoTree\" | select FullName'

          [PsCustomObject]@{
            Name = "Get all files"
            Run =
              $run -replace "\`$PsScriptRoot", (Get-Location).Path
            Value = iex `
              ($run -replace "\`$PsScriptRoot", (Get-Location).Path)
          }
        ),

        $(
          $run = 'Get-DemandScript -All -Directory "$PSScriptRoot\res\DemandFile_DemoTree\" | Get-DemandMatch'

          [PsCustomObject]@{
            Name = "Get all tags"
            Run =
              $run -replace "\`$PsScriptRoot", (Get-Location).Path
            Value = iex `
              ($run -replace "\`$PsScriptRoot", (Get-Location).Path)
          }
        )
      ) + @(
        foreach ($item in `
          (Get-DemandScript `
            -All `
            -Directory `
              "$PsScriptRoot\..\res\DemandFile_DemoTree\" |
            Get-DemandMatch).
            Matches
        ) {
          $run = 'Get-DemandScript -InputObject $item -Directory "$PsScriptRoot\res\DemandFile_DemoTree\"'

          [PsCustomObject]@{
            Name = "Get files matching tag '$item'"
            Run = ($run -replace `
              "\`$item", `
              $item) -replace `
              "\`$PsScriptRoot", `
              (Get-Location).Path
            Value = iex ($run -replace `
              "\`$PsScriptRoot", `
              (Get-Location).Path)
          }
        }
      )
    }
  } |
  ConvertTo-Json `
    -Depth $depth |
  Out-FileUnix `
    -FilePath "$PsScriptRoot\..\res\Get-DemandScript.Mock.json" `
    -Encoding utf8 `
    -Force:$Force
}
