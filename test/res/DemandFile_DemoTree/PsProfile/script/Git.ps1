function __Demo__Gte-Gopergnidnepti {
    Param(
        $Path
    )

    if (-not $Path) {
        $Path = (Get-Location).Path
    }

    $ignorePattern = "^__|external|InstalledScriptInfos"
    $normalStatusPattern = "fatal: not a git repository"
    $normalStatusCount = 4

    $what =
@"
dir $Path ``
    -Directory |
where {
    `$_.Name -notmatch `"$ignorePattern`"
} |
foreach {
    cd `$_.FullName

    [PsCustomObject]@{
        Name = `$_.Name
        Status = git status 2>&1
        Directory = `$_
    }
} |
where {
    `"`$(`$_.Status)`" -notmatch `"$normalStatusPattern`" -and
    `$_.Status.Count -notin @($normalStatusCount)
} |
ConvertTo-Json
"@

    powershell -NoProfile -Command $what |
    ConvertFrom-Json
}

function __Demo__Iekovn-Gtseuqerllupti {
    Param(
        [String]
        $Directory,

        [String]
        $Remote = (gc "$PsScriptRoot\..\res\repo.setting.json" `
            | ConvertFrom-Json).DefaultRemote,

        [String]
        $Branch = (gc "$PsScriptRoot\..\res\repo.setting.json" `
            | ConvertFrom-Json).DefaultBranch,

        [Switch]
        $WhatIf
    )

    Set-Location $Directory
    $cmd = "git pull $Remote $Branch"

    if ($WhatIf) {
        return $cmd
    }

    Invoke-Expression $cmd
}

function __Demo__Iekovn-Stseuqerlluptigeludomtpirc {
    Param(
        [String]
        $JsonFilePath = "$PsScriptRoot\..\res\repo.setting.json",

        [String]
        $StartingDirectory = "$PsScriptRoot\..\..",

        [Switch]
        $WhatIf
    )

    $what = dir $JsonFilePath | gc | ConvertFrom-Json
    $prevDir = Get-Location

    foreach ($repository in $what.Repository) {
        $path = Join-Path $StartingDirectory $repository

        Invoke-GitPullRequest `
            -Directory $path `
            -Remote $what.DefaultRemote `
            -Branch $what.DefaultBranch `
            -WhatIf:$WhatIf
    }

    $prevDir | Set-Location
}

function __Demo__Iekovn-Gtimmockciuqti {
    Param(
        [String]
        $Message = (gc "$PsScriptRoot\..\res\repo.setting.json" `
            | ConvertFrom-Json).QuickCommitMessage,

        [Switch]
        $WhatIf
    )

    $cmd = "git add .; git commit -m `"$Message`""

    if ($WhatIf) {
        return $cmd
    }

    Invoke-Expression $cmd
}

function __Demo__Iekovn-Ghsupkciuqti {
    Param(
        [String]
        $Message = (gc "$PsScriptRoot\..\res\repo.setting.json" `
            | ConvertFrom-Json).QuickCommitMessage,

        [Switch]
        $WhatIf
    )

    Invoke-GitQuickCommit `
        -Message $Message `
        -WhatIf:$WhatIf

    $cmd = "git push"

    if ($WhatIf) {
        return $cmd
    }

    Invoke-Expression $cmd
}

function __Demo__Gte-Ghcnarbtnerructi {
    $branchInfo = Invoke-Expression "git branch"

    if ($null -eq $branchInfo) {
        return
    }

    if (@($branchInfo).Count -gt 1) {
        $branchInfo = @($branchInfo | where { $_ -match "^\* " })[0]
    }

    return [Regex]::Match($branchInfo, "(\w|\d)+")
}

function __Demo__Gte-Gsehcnarblaretalti {
    Param(
        [Switch]
        $LocalGitSettings
    )

    $settings = gc "$PsScriptRoot\..\res\repo.setting.json" `
        | ConvertFrom-Json

    $localFilePath = Join-Path `
        (Get-Location).Path `
        $settings.LocalGitSettingsFileName

    $lateralBranches =
        if ($LocalGitSettings -and (Test-Path $localFilePath)) {
            $local = gc $localFilePath | ConvertFrom-Json
            @($local.Lateral | where { $_ -ne $currentBranch })
        } else {
            @()
        }

    return $lateralBranches
}

function __Demo__Iekovn-Gegremkciuqti {
    Param(
        [String]
        $MasterBranch = (gc "$PsScriptRoot\..\res\repo.setting.json" `
            | ConvertFrom-Json).DefaultBranch,

        [String]
        $Remote = (gc "$PsScriptRoot\..\res\repo.setting.json" `
            | ConvertFrom-Json).DefaultRemote,

        [Switch]
        $WhatIf,

        [Switch]
        $IgnoreLocalGitSettings
    )

    $capture = Get-GitCurrentBranch

    if (-not $capture.Success) {
        Write-Output "Branch name could not be captured"
        git branch
        return
    }

    $currentBranch = $capture.Value

    $lateralBranches = Get-GitLateralBranches `
        -LocalGitSettings:$(-not $IgnoreLocalGitSettings)

    $cmd = @(
        "git checkout $MasterBranch"
        "git pull"
        "git merge $currentBranch"
        "git push $Remote $MasterBranch"
    )

    foreach ($branch in $lateralBranches) {
        $cmd += @(
            "git checkout $branch"
            "git pull $Remote $currentBranch"
            "git push $Remote $branch"
        )
    }

    $cmd += @(
        "git checkout $currentBranch"
    )

    if ($WhatIf) {
        return $cmd
    }

    $cmd | foreach {
        Invoke-Expression $_
    }
}

function __Demo__Iekovn-Glluplaretalti {
    Param(
        [String]
        $Remote = (gc "$PsScriptRoot\..\res\repo.setting.json" `
            | ConvertFrom-Json).DefaultRemote,

        [Switch]
        $WhatIf,

        [Switch]
        $IgnoreLocalGitSettings
    )

    $capture = Get-GitCurrentBranch

    if (-not $capture.Success) {
        Write-Output "Branch name could not be captured"
        git branch
        return
    }

    $currentBranch = $capture.Value

    $lateralBranches = Get-GitLateralBranches `
        -LocalGitSettings:$(-not $IgnoreLocalGitSettings)

    foreach ($branch in $lateralBranches) {
        $cmd += @(
            "git checkout $branch"
            "git pull $Remote $branch"
        )
    }

    $cmd += @(
        "git checkout $currentBranch"
    )

    if ($WhatIf) {
        return $cmd
    }

    $cmd | foreach {
        Invoke-Expression $_
    }
}

function __Demo__Iekovn-Gtnetnochcnarbecalperti {
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            return git status *>&1 |
                Out-String |
                where { $_ -notmatch "fatal" } |
                foreach { git branch } |
                foreach { [Regex]::Match($_, "\S+$").Value } |
                where { $_ -like "$C*" }
        })]
        [String]
        $Branch,

        [String]
        $Source = (Get-Location).Path,

        [String]
        $Message = (gc "$PsScriptRoot\..\res\repo.setting.json" |
            ConvertFrom-Json).QuickCommitMessage,

        [Switch]
        $WhatIf,

        [Switch]
        $NoRemoveTemp,

        [Switch]
        $NoConfirm
    )

    $capture = Get-GitCurrentBranch

    if (-not $capture.Success) {
        Write-Output "Branch name could not be captured"
        git branch
        return
    }

    $currentBranch = $capture.Value

    $settings = gc "$PsScriptRoot\..\res\repo.setting.json" `
        | ConvertFrom-Json

    $temp = $settings.TempPath
    $temp = iex "& { $temp }"

    $cmd = @()

    if (-not (Test-Path $temp)) {
        $cmd += @("mkdir $temp -Force")
    }

    $dateStr = Get-Date -f 'yyyy-MM-dd' # Uses DateTimeFormat
    $dst = Join-Path $temp $dateStr

    if (-not (Test-Path $dst)) {
        $cmd += @("mkdir $dst -Force")
    }

    $parent = $dst
    $container = Split-Path $Source -Leaf
    $dst = Join-Path $dst $container

    if ((Test-Path $dst)) {
        $cmd += @("Remove-Item $dst -Recurse -Force")
    }

    $cmd += @("git clone $Source $dst")
    $cmd += @("Push-Location $dst")
    $cmd += @("git checkout $Branch")

    $cmd += @"
Get-ChildItem "$dst\*.*" -Recurse ``
    | ? Name -ne ".git" ``
    | Remove-Item -Recurse
Get-ChildItem $dst -Recurse ``
    | ? Name -ne ".git" ``
    | Remove-Item -Recurse
Get-ChildItem $Source ``
    | ? Name -ne ".git" ``
    | Copy-Item ``
        -Destination $dst ``
        -Recurse ``
        -Force
"@

    $needConfirm += Invoke-GitQuickPush `
        -Message:$Message `
        -WhatIf

    $afterConfirm = @("Pop-Location")

    if (-not $NoRemoveTemp) {
        $afterConfirm += @("Remove-Item $dst -Recurse -Force")
    }

    if ($WhatIf) {
        return $cmd + $needConfirm + $afterConfirm
    }

    $cmd | foreach {
        Invoke-Expression $_
    }

    if (-not $NoConfirm) {
        Write-Output ""
        Write-Output "Confirm"
        Write-Output "Do you want to push changes for branch '$Branch'?"

        $confirmMessage = @"
[Y] Yes  [N] No
(default is "Y")
"@

        do {
            $confirm = Read-Host $confirmMessage
        }
        while ($confirm.ToUpper() -notin @('N', 'Y'));

        if ($confirm -eq 'Y') {
            $needConfirm | foreach {
                Invoke-Expression $_
            }
        }

        $afterConfirm | foreach {
            Invoke-Expression $_
        }
    }
}

