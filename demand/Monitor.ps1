<#
.DESCRIPTION
Tags: process
#>
function Start-ProcessMonitor {
    Param(
        [scriptblock]
        $Process = { Get-Process },

        [string[]]
        $ExcludeProcess,

        [string]
        $ExcludePattern,

        [double]
        $Delay = 0.01
    )

    $maxLength = 40
    $prev = & $Process
    $activity = $Process.ToString()

    if ($activity.Length -gt $maxLength) {
        $activity = $activity.Substring(0, $maxLength - 4) + ' ...'
    }

    $activity = "Running monitor {$activity}"
    $status = "Press 'Ctrl + C' to stop"

    while ($true) {
        Write-Progress `
            -Activity $activity `
            -Status $status `
            -PercentComplete 0

        $next = & $Process

        $diff = Compare-Object `
            ($prev | where Name -notin $ExcludeProcess) `
            ($next | where Name -notin $ExcludeProcess)

        if ($ExcludePattern) {
            $diff = $diff | where {
                $_.InputObject -notmatch $ExcludePattern
            }
        }

        if ($diff) {
            "[$(Get-Date -f 'HH:mm:ss:fff')]"

            foreach ($item in $diff) {
                switch ($item.SideIndicator) {
                    '<=' { "- Removed - $($item.InputObject)" }
                    '=>' { "- Added   - $($item.InputObject)" }
                }
            }

            ''
        }

        $prev = $next
        Start-Sleep $Delay
    }

    Write-Progress `
        -Activity $activity `
        -Complete
}

