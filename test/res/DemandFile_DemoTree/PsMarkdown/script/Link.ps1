function __Demo__Gte-Mesrapsknilnwodkra {
    [Alias('MdLink')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $Directory,

        [Switch]
        $All,

        [Switch]
        $Cat,

        [Switch]
        $TestWebLink,

        [Switch]
        $PassThru
    )

    Begin {
        $dirs = @()
    }

    Process {
        $dirs += @($Directory)
    }

    End {
        $links = $dirs | foreach -Begin {
            $count = 1
        } -Process {
            $progressParam = @{
                Id = 1
                Activity = "Testing Items"
                Status =
                    if ([String]::IsNullOrEmpty("$_")) {
                        "..."
                    }
                    else {
                        $_
                    }
                PercentComplete = 100 * $count / $dirs.Count
            }

            Write-Progress @progressParam
            $count = $count + 1

            Get-MarkdownLink `
                -Directory $_ `
                -Cat:$Cat `
                -TestWebLink:$TestWebLink `
                -PassThru:$PassThru
        }

        $progressParam = @{
            Id = 1
            Activity = "Testing Items"
            Complete = $true
        }

        Write-Progress @progressParam

        $links = if ($All) {
            $links
        } else {
            @($links)[0]
        }

        if ($null -eq $links -or @($links).Count -eq 0) {
            return $links
        }

        $links = if ($PassThru) {
            $links
        } else {
            $links.LinkPath
        }

        return $links
    }
}

function __Demo__Gte-Mknilnwodkra {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $Directory,

        [Switch]
        $Cat,

        [Switch]
        $TestWebLink,

        [Switch]
        $PassThru
    )

    Begin {
        function Test-WebRequest {
            Param(
                [String]
                $Uri
            )

            $HTTP_Response =
                [System.Net.WebRequest]::Create($Uri).
                GetResponse()

            if ($null -eq $HTTP_Response) {
                return $null
            }

            $HTTP_Status = [Int] $HTTP_Response.StatusCode
            $HTTP_Response.Close()
            return 200 -eq $HTTP_Status
        }

        function Get-CaptureGroupName {
            Param(
                [Object[]]
                $MatchInfo
            )

            $groups = $MatchInfo.Groups |
                where {
                    $_.Success -and
                    $_.Length -gt 0 -and
                    $_.Name -notmatch "\d+"
                }

            return $groups.Name
        }

        function Get-CaptureGroup {
            Param(
                [Parameter(ValueFromPipeline = $true)]
                [Object]
                $MatchInfo,

                [Switch]
                $TestWebLink,

                [Switch]
                $PassThru
            )

            Begin {
                $list = @()
            }

            Process {
                $list += @($MatchInfo)
            }

            End {
                $count = 0

                foreach ($item in $list) {
                    $linkPath = $item.Path

                    foreach ($capture in $item.Matches) {
                        $groupName = Get-CaptureGroupName $capture
                        $value = $capture.Groups[$groupName].Value

                        if (@($groupName).Count -gt 0) {
                            $groupName = @($groupName)[0]
                        }

                        if ([String]::IsNullOrWhiteSpace($value)) {
                            continue
                        }

                        $searchMethod = ''

                        switch -Regex ($value) {
                            '^\.\.?(\\|\/)' {
                                $searchMethod = 'Relative'
                                $parent = Split-Path $linkPath -Parent

                                $linkPath = switch ($linkPath) {
                                    'InputStream' {
                                        $linkPath
                                    }

                                    default {
                                        Join-Path $parent $value
                                    }
                                }
                            }

                            default {
                                $searchMethod = 'Absolute'
                                $linkPath = $value
                            }
                        }

                        $isWebLink = $TestWebLink -and $groupName -eq 'Web'

                        $progressParam = @{
                            Id = 2
                            Activity = "Testing Links"
                            Status =
                                if ($isWebLink) {
                                    "Test-WebRequest: $linkPath"
                                } else {
                                    "Test-Path: $linkPath"
                                }
                            PercentComplete = 100 * $count / $list.Count
                        }

                        Write-Progress @progressParam
                        $count = $count + 1

                        $found = if ($isWebLink) {
                            Test-WebRequest -Uri $linkPath
                        } else {
                            Test-Path $linkPath
                        }

                        $obj = [PsCustomObject]@{
                            Capture = $value
                            Type = $groupName
                            SearchMethod = $searchMethod
                            Found = $found
                            LinkPath = $linkPath
                            FilePath = $item.Path
                            Protocol =
                                [Regex]::Match(
                                    $linkPath,
                                    "^(\w|\d)+(?=://)"
                                ).Value
                        }

                        if ($PassThru) {
                            $obj | Add-Member `
                                -MemberType 'NoteProperty' `
                                -Name 'MatchInfo' `
                                -Value $item
                        }

                        Write-Output $obj
                    }
                }

                $progressParam = @{
                    Id = 2
                    Activity = "Testing Links"
                    Complete = $true
                }

                Write-Progress @progressParam
            }
        }

        $webPattern = "(?<=\<)[^\<\>]*(?=\>)"
        $barePattern = "https?://[^\s`"\(\)\<\>]+"
        $linkPattern = "\[[^\[\]]*\]\()[^\(\)]+(?=\))"
        $referencePattern = "(?<=$linkPattern"
        $imagePattern = "(?<=!$linkPattern"
        $searchPattern =
            "(?<Web>$webPattern)|(?<Bare>$barePattern)|(?<Image>$imagePattern)|(?<Reference>$referencePattern)"

        $list = @()
    }

    Process {
        if (-not $Cat) {
            $Directory = switch ($Directory) {
                { $_ -is [String] } {
                    Get-ChildItem $Directory
                }

                { $_ -is [Microsoft.PowerShell.Commands.MatchInfo] } {
                    Get-ChildItem $Directory.Path
                }

                { $_ -is [System.IO.FileSystemInfo] } {
                    $Directory
                }
            }
        }

        $list += @($Directory |
            Select-MarkdownString $searchPattern)
    }

    End {
        return $list | Get-CaptureGroup `
            -TestWebLink:$TestWebLink `
            -PassThru:$PassThru
    }
}

function __Demo__Ctrevno-Mrevloserknilnwodkra {
    Param(
        [Parameter(
            ParameterSetName = 'ByCustomObject',
            ValueFromPipeline = $true
        )]
        [PsCustomObject]
        $InputObject,

        [Parameter(
            ParameterSetName = 'ByTwoStrings'
        )]
        [String]
        $OriginPath,

        [Parameter(
            ParameterSetName = 'ByTwoStrings'
        )]
        [String]
        $DestinationPath,

        [ValidateSet('Absolute', 'Relative')]
        [String]
        $SearchMethod = 'Relative'
    )

    Begin {
        function Get-CommonPrefix {
            Param(
                [String]
                $InputString,

                [String]
                $ReferenceString
            )

            $iList = $InputString.Replace('\', '/').Split('/')
            $rList = $ReferenceString.Replace('\', '/').Split('/')
            $iEnum = 0
            $rEnum = 0
            $prefix = @()

            while ($iEnum -lt $iList.Count -and $rEnum -lt $rList.Count) {
                if ($iList[$iEnum] -ne $rList[$rEnum]) {
                    break
                }

                $prefix += @($iList[$iEnum])
                $iEnum++
                $rEnum++
            }

            $iTail = @()

            while ($iEnum -lt $iList.Count) {
                $iTail += @($iList[$iEnum])
                $iEnum++
            }

            $rTail = @()

            while ($rEnum -lt $rList.Count) {
                $rTail += @($rList[$rEnum])
                $rEnum++
            }

            return [PsCustomObject]@{
                Prefix = $prefix -Join '/'
                InputTail = $iTail -Join '/'
                ReferenceTail = $rTail -Join '/'
            }
        }

        function Format-Link {
            Param(
                [Parameter(ValueFromPipeline = $true)]
                [String]
                $Link
            )

            return $Link.
                Trim().
                Replace('\', '/') |
                foreach { $_ -Replace '^\./\.\./', '../' } |
                foreach { $_ -Replace '(?<=.+/)\./', '' }
        }
    }

    Process {
        switch ($PsCmdlet.ParameterSetName) {
            'ByCustomObject' {
                $OriginPath = $InputObject.FilePath
                $DestinationPath = $InputObject.LinkPath
            }
        }

        $dir = dir $OriginPath -ErrorAction 'SilentlyContinue'
        $OriginPath = $OriginPath.Replace('\', '/')
        $DestinationPath = $DestinationPath.Replace('\', '/')

        $what = Get-CommonPrefix `
            -InputString $OriginPath `
            -ReferenceString $DestinationPath

        switch ($SearchMethod) {
            'Relative' {
                $nodes =
                    if ([String]::IsNullOrWhiteSpace($what.InputTail)) {
                        0
                    } else {
                        "$($what.InputTail)".
                            Trim('/').
                            Split('/').
                            Count
                    }

                $fullPath = Join-Path `
                    -Path '.' `
                    -ChildPath $(
                        (1 .. ($nodes - 1) |
                        foreach { '..' }) `
                        -Join '\'
                    ) `
                    -AdditionalChildPath $what.ReferenceTail

                return Format-Link $fullPath
            }

            'Absolute' {
                if ($null -ne $dir -and $dir.Mode -match '^-a') {
                    $OriginPath = Split-Path $OriginPath -Parent
                }

                $originList =
                    $OriginPath.Replace('\', '/').Split('/')

                $refTailList =
                    $what.ReferenceTail.Replace('\', '/').Split('/')

                if ($refTailList[0] -eq '.') {
                    $refTailList =
                        $refTailList[1 .. ($refTailList.Count - 1)]
                }

                while (
                    $refTailList[0] -eq '..' -and `
                    $originList.Count -gt 0
                ) {
                    $refTailList = if ($refTailList.Count -eq 1) {
                        @()
                    } else {
                        $refTailList[1 .. ($refTailList.Count - 1)]
                    }

                    $originList = if ($originList.Count -eq 1) {
                        @()
                    } else {
                        $originList[0 .. ($originList.Count - 2)]
                    }
                }

                return Join-Path `
                    ($originList -Join '/') `
                    ($refTailList -Join '/') `
                    | Format-Link
            }
        }
    }
}

function __Demo__Mevo-Mmetinwodkra {
    Param(
        [String]
        $Source,

        [String]
        $Destination,

        [Switch]
        $Force,

        [String]
        $Notebook
    )

    function Get-MarkdownLocalResource {
        Param(
            [Alias('Path')]
            [String]
            $ItemPath
        )

        $pattern = "!\[[^\[\]]+\]\((?<Resource>[^\(\)]+)\)"
        $dir = (Get-Item $ItemPath).Directory

        foreach ($line in (gc $ItemPath)) {
            $capture = [Regex]::Match($line, $pattern)

            if ($capture.Success) {
                $value = $capture.Groups['Resource'].Value
                $resourcePath = Join-Path $dir $value
                $exists = Test-Path $resourcePath

                [PsCustomObject]@{
                    String = $value
                    Path = $resourcePath
                    Exists = $exists
                    FileInfo = if ($exists) {
                        Get-Item $resourcePath
                    } else {
                        $null
                    }
                }
            }
        }
    }

    function Get-MarkdownItemMovedContent {
        Param(
            [Parameter(ValueFromPipeline = $true)]
            $Source,

            [String]
            $Destination,

            [String]
            $Notebook
        )

        Process {
            if ($Source -is [String]) {
                $Source = Get-ChildItem $Source
            }

            foreach ($item in $Source) {
                $links = $item | Get-MarkdownLink -PassThru | where {
                    $_.Type -eq 'Reference'
                } | where {
                    $_.SearchMethod -eq 'Relative'
                }

                $cat = $item | Get-Content

                $Destination = Join-Path `
                    (Get-Item $Destination).FullName `
                    (Split-Path $item -Leaf)

                foreach ($link in $links) {
                    $capture = $link.MatchInfo.Matches[0].Groups[$link.Type]

                    if ($link.Type -in @('Web', 'Bare')) {
                        continue
                    }

                    $newLink = Convert-MarkdownLinkResolver `
                        -OriginPath $link.FilePath `
                        -DestinationPath $link.Capture `
                        -SearchMethod Absolute

                    $newLink = Convert-MarkdownLinkResolver `
                        -OriginPath $Destination `
                        -DestinationPath $newLink `
                        -SearchMethod Relative

                    $matchInfo = $link.MatchInfo

                    $newLine =
                        $matchInfo.Line.Substring(0, $capture.Index) +
                            $newLink +
                            $matchInfo.Line.Substring(
                                $capture.Index + $capture.Length
                            )

                    $cat[$matchInfo.LineNumber - 1] = $newLine
                }

                $moveItem = [PsCustomObject]@{
                    Path = $Destination
                    Content = $cat
                    BackReferences = @()
                    ChangeLinks = @(
                        [PsCustomObject]@{
                            FilePath = $Destination
                            LineNumber = $matchInfo.LineNumber
                            Old = $matchInfo.Line
                            New = $newLine
                        }
                    )
                }

                $grep = dir $Notebook -Recurse `
                    | Get-MarkdownLink -PassThru | where {
                        $_.Type -eq 'Reference'
                    } | where {
                        $_.SearchMethod -eq 'Relative'
                    } | where {
                        $_.Capture -match (Split-Path $item -Leaf)
                    }

                $cats = @{}

                foreach ($item in $grep) {
                    if ($null -eq $cats[$item.FilePath]) {
                        $cats[$item.FilePath] = gc $item.FilePath
                    }

                    $matchInfo = $item.MatchInfo
                    $capture = $matchInfo.Matches[0]

                    $newLink = Convert-MarkdownLinkResolver `
                        -OriginPath $item.FilePath `
                        -DestinationPath $capture.Value `
                        -SearchMethod Absolute

                    $newLink = Convert-MarkdownLinkResolver `
                        -OriginPath $item.FilePath `
                        -DestinationPath $Destination `
                        -SearchMethod Relative

                    $newLine =
                        $matchInfo.Line.Substring(0, $capture.Index) +
                            $newLink +
                            $matchInfo.Line.Substring(
                                $capture.Index + $capture.Length
                            )

                    $cats[$matchInfo.Path][$matchInfo.LineNumber - 1] =
                        $newLine
                }

                $moveItem.BackReferences = $cats.Keys | sort | foreach {
                    [PsCustomObject]@{
                        Path = $_
                        Content = $cats[$_]
                    }
                }

                $moveItem.ChangeLinks += @(
                    [PsCustomObject]@{
                        FilePath = $item.FullName
                        LineNumber = $matchInfo.LineNumber
                        Old = $matchInfo.Line
                        New = $newLine
                    }
                )

                return $moveItem
            }
        }
    }

    if (-not $Notebook) {
        $setting = gc "$PsScriptRoot/../res/setting.json" `
            | ConvertFrom-Json

        $Notebook = $setting.Link.Notebook
    }

    $dir = (Get-Item $Source).Directory

    $resource = Get-MarkdownLocalResource `
        -ItemPath $Source

    $moveLinkInfo = @()

    if ($Notebook) {
        $moveLinkInfo = Get-MarkdownItemMovedContent `
            -Source $Source `
            -Destination $Destination `
            -Notebook $Notebook
    }

    foreach ($subitem in $resource) {
        $resourceDest = Join-Path $Destination $subitem.String
        $parentPath = Split-Path $subitem.String
        $resourceParentDest = Join-Path $Destination $parentPath

        if (-not (Test-Path $resourceParentDest)) {
            New-Item `
                -Path $resourceParentDest `
                -ItemType Directory `
                -Force:$Force
        }

        Move-Item `
            -Path $subitem.Path `
            -Destination $resourceDest `
            -Force:$Force
    }

    Move-Item `
        -Path $Source `
        -Destination $Destination `
        -Force:$Force

    $Destination = Join-Path `
        (Get-Item $Destination).FullName `
        (Split-Path $Source -Leaf)

    if ($Notebook) {
        $moveLinkInfo.Content | Out-File $Destination -Force

        if (diff ($moveLinkInfo.Content) (gc $Destination)) {
            Write-Warning "Failed to write file $($Destination)"
        }
        else {
            Write-Output $moveLinkInfo.ChangeLinks[0]
        }

        foreach ($backRef in $moveLinkInfo.BackReferences) {
            $backRef.Content | Out-File $backRef.Path -Force

            if (diff ($backRef.Content) (gc $backRef.Path)) {
                Write-Warning "Failed to write file $($backRef.Path)"
            }
            else {
                Write-Output $moveLinkInfo.ChangeLinks | where {
                    $_.FilePath -eq $backRef.Path
                }
            }
        }
    }
}
