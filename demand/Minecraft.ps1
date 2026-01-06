<#
.DESCRIPTION
Requires: 7zip
#>

function Save-MinecraftWorld {
    [Alias('minec')]
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            $suggest =
                "$PsScriptRoot/../res/minecraft.setting.json" |
                Get-Item |
                Get-Content |
                ConvertFrom-Json |
                foreach { $_.SaveDirectoryExp } |
                Invoke-Expression |
                Get-ChildItem |
                foreach { $_.Name }

            $completers =
                $suggest |
                where { $_ -like "$C*" }

            @(if ($completers) {
                $completers
            }
            else {
                $suggest
            }) |
            foreach {
                if ($_ -match "\s") {
                    "`"$_`""
                }
                else {
                    $_
                }
            }
        })]
        [AllowNull()]
        [Parameter(
            ValueFromPipeline = $true,
            Position = 0
        )]
        [string]
        $Name,

        [switch]
        $WhatIf
    )

    $setting = "$PsScriptRoot/../res/minecraft.setting.json" |
        Get-Item |
        Get-Content |
        ConvertFrom-Json

    $sourceDir = $setting.SaveDirectoryExp | Invoke-Expression
    $destDir = $setting.BackupDirectoryExp | Invoke-Expression

    if (-not $Name) {
        $Name = dir $sourceDir |
            Sort-Object -Property LastWriteTime -Descending |
            Select-Object -First 1 |
            foreach { $_.Name }
    }

    $item = Join-Path $sourceDir $Name | Get-Item
    $datetime = Get-Date -f yyyy-MM-dd-HHmmss  # Uses DateTimeFormat
    $command = "7z a -r -t7z"

    $command = if ($item.PsIsContainer) {
        "$command `"$destDir/$($item.Name)-$datetime`" `"$($item.FullName)/*.*`""
    }
    else {
        "$command `"$destDir/$($item.BaseName)-$datetime`" `"$($item.FullName)`""
    }

    if ($WhatIf) {
        [pscustomobject]@{
            Command = $command
            Source = $sourceDir
            Destination = $destDir
        }
    }
    else {
        Invoke-Expression $command
    }
}

