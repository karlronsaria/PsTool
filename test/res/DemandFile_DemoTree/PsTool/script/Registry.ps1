<#
.SYNOPSIS
Replace all registry key values and/or registry key names under a given path.

.LINK
Url: <https://stackoverflow.com/questions/26680410/powershell-find-and-replace-on-registry-values>
Retrieved: 2020-04-09

.LINK
Url: <https://stackoverflow.com/users/684576/david-maisonave>
Retrieved: 2020-04-09

.EXAMPLE
Rename-ItemProperty "ExistingValue" "NewValue" 'HKEY_CURRENT_USER\Software\100000_DummyData'

.EXAMPLE
Rename-ItemProperty "ExistingValue" "NewValue" 'HKEY_USERS\*\Software\100000_DummyData' -ReplaceKeyNames $true -CaseSensitive $true

.EXAMPLE
Rename-ItemProperty 'C:\\Program Files\\Microsoft SQL Server' 'E:\Program Files\Microsoft SQL Server' 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server*' -Verbose

.PARAMETER CaseSensitive
Flag: Specifies that Search and Replace is case sensitive

.PARAMETER WholeWord
Flag: Specifies to search for the whole word within a value

.PARAMETER ExactMatch
Flag: Specifies that the entire value must match OldValue, and partial replacements are NOT performed

.PARAMETER ReplaceKeyNames
Flag: Specifies that registry key names will be replaced

.PARAMETER ReplaceValues
Flag: Specifies that registry key values will be replaced

.PARAMETER Verbose
#>
function __Demo__Remane-Iytreporpmet {
    Param(
        [String] $OldValue = $(throw "OldValue (the current value) required."),
        [String] $NewValue = $(throw "NewValue (the replacement value) required."),
        [String] $ItemPath = $(throw "ItemPath (The full registry key path) required."),
        [Switch] $CaseSensitive,
        [Switch] $WholeWord,
        [Switch] $ExactMatch,
        [Switch] $ReplaceKeyNames,
        [Switch] $ReplaceValues,
        [Switch] $Verbose
    )

    function Test-Match {
        Param(
            $InputObject,
            [String] $OldValue,
            [String] $Pattern,
            [Switch] $ExactMatch,
            [Switch] $CaseSensitive
        )

        return $(if ($ExactMatch) {
            $InputObject -clike $OldValue
        }
        else {
            if ($CaseSensitive) {
                $InputObject -cmatch $Pattern
            }
            else {
                $InputObject -match $Pattern
            }
        })
    }

    $powershellRegPrefix =
        'Microsoft.PowerShell.Core\Registry::'

    $pattern = if ($WholeWord) {
        ".*\b$OldValue\b.*"
    }
    else {
        ".*$OldValue.*"
    }

    if ($ItemPath -NotLike "$powershellRegPrefix*") {
        $ItemPath = $powershellRegPrefix + $ItemPath
    }

    $worklist =
        @(Get-Item -ErrorAction SilentlyContinue -Path $ItemPath) + `
        @(Get-ChildItem -Recurse $ItemPath -ErrorAction SilentlyContinue)

    foreach ($item in (
        $worklist |
        foreach {
            Get-ItemProperty -Path "$powershellRegPrefix$_"
        }
    )) {
        $psPath = $item.PSPath

        foreach ($property in $item.PsObject.Properties) {
            $found = $property.Name -cne "PSChildName" `
                -and (Test-Match `
                    -InputObject $property.Value `
                    -OldValue $OldValue `
                    -Pattern $pattern `
                    -ExactMatch:$ExactMatch `
                    -CaseSensitive:$CaseSensitive)

            if (-not $found) {
                continue
            }

            $original = $property.Value
            $createNewValue = $property.Value
            $subkeyName = $property.Name
            $keyName = "$psPath->$subkeyName"

            $createNewValue = if ($CaseSensitive) {
                $createNewValue -creplace $OldValue, $NewValue
            }
            else {
                $createNewValue -replace $OldValue, $NewValue
            }

            if ($property.Name -eq "PSPath" -and $property.Value -eq $psPath) {
                if ($ReplaceKeyNames) {
                    Move-Item -Path $psPath -Destination $createNewValue

                    if ($Verbose) {
                        Write-Output "Renamed registry key '$psPath' to '$createNewValue'"
                    }
                }
                else {
                    if ($Verbose) {
                        Write-Output "Skipping renaming key '$keyName'..."
                    }
                }
            } else {
                if ($ReplaceValues) {
                    Set-ItemProperty `
                        -Path $psPath `
                        -Name $property.Name `
                        -Value $createNewValue

                    if ($Verbose) {
                        Write-Output "Renamed '$original' to '$createNewValue' for registry key '$keyName'"
                    }
                }
                else {
                    if ($Verbose) {
                        Write-Output "Skipping renaming value '$keyName'..."
                    }
                }
            }
        }
    }
}

