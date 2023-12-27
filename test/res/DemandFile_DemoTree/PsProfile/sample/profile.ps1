Import-Module Posh-Git

$loc = "$($env:OneDrive)\Documents\WindowsPowerShell"

$myScripts = @(
    "$loc\Scripts\PsFrivolous\script\PsalmOfTheDay.ps1"
)

$myModules = @(
    "$loc\Scripts\PsProfile\Get-Scripts.ps1"
    "\shortcut\dos\ps\ShortcutGoogleChrome\Get-Scripts.ps1"
)

$myScripts | foreach {
    . $_
}

$myModules | foreach {
    iex $_ | foreach { . $_ }
}

New-Alias `
    -Name 'gchrome' `
    -Value 'Run-ShortcutGoogleChromeProfile'

# Store previous command's output in `$__`
$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'

# link
# - url: <https://stackoverflow.com/questions/40098771/changing-powershells-default-output-encoding-to-utf-8>
# - retrieved: 2023_01_16
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

Invoke-Expression (Get-ScriptModuleSourceCommand -ShowProgress)
Import-DemandModule

Set-PsReadLineOption -EditMode Vi
