<#
.LINK
Url: <https://livebook.manning.com/book/powershell-in-depth/chapter-37/15>
Retrieved: 2023-04-09
#>
function Get-ProxyFunction {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [Alias("Command", "CommandName")]
        [String]
        $Name
    )

    try {
        if ([String]::IsNullOrWhiteSpace($Name)) {
            return
        }

        [System.Management.Automation.ProxyCommand]::Create((
            New-Object System.Management.Automation.CommandMetaData(Get-Command $Name)
        ))
    }
    catch {
        throw
    }
}
