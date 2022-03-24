<#
    .LINK
        https://livebook.manning.com/book/powershell-in-depth/chapter-37/15
#>
function Get-ProxyFunction {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [Alias("Command", "CommandName")]
        [String]
        $Name
    )

    try {
        if ($Name) {
            $metadata = New-Object System.Management.Automation.CommandMetaData(Get-Command $Name)
            return [System.Management.Automation.ProxyCommand]::Create($metadata)
        }
    }
    catch {
        throw
    }
}
