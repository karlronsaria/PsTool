#Requires -Module PSReadLine

. "$PsScriptRoot/Git.ps1"

<#
.LINK
- Url: <https://serverfault.com/questions/95431/in-a-powershell-script-how-can-i-check-if-im-running-with-administrator-privil>
- Retrieved: 2023_01_04
#>
function __Demo__Ttse-Rrotartsinimasielo {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole($adminRole)
}

function __Demo__Gte-Pnoitacolelifor {
    [CmdletBinding(DefaultParameterSetName = "ByCurrentApp")]
    Param(
        [Parameter(ParameterSetName = "ByDefault")]
        [Switch]
        $Default,

        [Parameter(ParameterSetName = "BySelect")]
        [ArgumentCompleter({
            $validateSet = @(5, 7)
            $version = $PsVersionTable.PsVersion.Major

            return @($validateSet | where {
                $_ -ne $version
            }) + @($version)
        })]
        [ValidateScript({
            return $_ -in @(0, 5, 7)
        })]
        [Int]
        $Version
    )

    $Version = switch ($PsCmdlet.ParameterSetName) {
        "ByCurrentApp" {
            0
        }

        "ByDefault" {
            (gc "$PsScriptRoot/../res/setting.json" |
                ConvertFrom-Json).
                ProfileLocation.
                DefaultVersion
        }

        "BySelect" {
            $Version
        }
    }

    $apps = @{
        5 = "powershell"
        7 = "pwsh"
    }

    $itemName = switch ($Version) {
        0 { $PROFILE }
        default {
            $app = $apps[$Version]
            $cmd = { & $app -NoProfile -Command "`$PROFILE" }

            Write-Progress `
                -Id 1 `
                -Activity "Running '$app'" `
                -Status "Please wait..." `
                -PercentComplete 50

            & $cmd

            Write-Progress `
                -Id 1 `
                -Activity "Running command" `
                -PercentComplete 100 `
                -Complete
        }
    }

    return Split-Path $itemName -Parent
}

function __Demo__Gte-Cyrotsihtsohelosno {
    Param(
        [Switch]
        $FilePath
    )

    $path =
    "$($env:APPDATA)/Microsoft/Windows/PowerShell/PSReadLine/ConsoleHost_history.txt"

    if ($FilePath) {
        return $path
    }

    gc $path
}

function __Demo__Rnu-Mdnammocy {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $Command,

        [Object[]]
        $ArgumentList
    )

    Invoke-Command `
        -ScriptBlock ([ScriptBlock]::Create($Command.Trim('"'))) `
        -ArgumentList:$ArgumentList
}

function __Demo__Gte-Sdnammocecruoseludomtpirc {
    Param(
        [String]
        $InfoDir,

        [String]
        $StartingDirectory,

        [Switch]
        $ShowProgress,

        [Switch]
        $ShowList
    )

    if (-not $InfoDir) {
        $InfoDir = "$PsScriptRoot/../res"
    }

    if (-not $StartingDirectory) {
        $StartingDirectory = "$PsScriptRoot/../.."
    }

    $showItem = if ($ShowList) {
@"
    `$item

"@
    }
    else {
        ""
    }

    $progress = if ($ShowProgress) {
@"
$showItem    `$count = `$count + 1

    Write-Progress ``
        -Activity "Loading script modules" ``
        -Status (dir `$item).Name ``
        -PercentComplete (100 * `$count / `$list.Count)
}

Write-Progress ``
    -Activity "Loading script modules" ``
    -PercentComplete 100 ``
    -Complete
"@
    }
    else {
@"
$showItem}
"@
    }

    $command =
@"
`$repo = dir '$InfoDir/repo.setting.json' |
    gc |
    ConvertFrom-Json

`$list = @(foreach (`$module in `$repo.ScriptModule) {
    iex "$StartingDirectory/`$module/Get-Scripts.ps1"
})

if ((Test-RoleIsAdministrator)) {
    `$list += @(foreach (`$module in `$repo.ElevatedScriptModule) {
        iex "$StartingDirectory/`$module/Get-Scripts.ps1"
    })
}

`$count = 0

foreach (`$item in `$list) {
    . `$item
$progress
"@

    return $command
}

New-Alias `
    -Name 'Pull-ScriptModule' `
    -Value 'Invoke-ScriptModuleGitPullRequest'

New-Alias `
    -Name 'Commit-Quick' `
    -Value 'Invoke-GitQuickCommit'

New-Alias `
    -Name 'Push-Quick' `
    -Value 'Invoke-GitQuickPush'

New-Alias `
    -Name 'Merge-Quick' `
    -Value 'Invoke-GitQuickMerge'

New-Alias `
    -Name 'Pull-Quick' `
    -Value 'Invoke-GitLateralPull'

