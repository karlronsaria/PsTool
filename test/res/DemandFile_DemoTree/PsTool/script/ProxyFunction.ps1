<#
.LINK
Url: <https://livebook.manning.com/book/powershell-in-depth/chapter-37/15>
Retrieved: 2023_04_09
#>
function __Demo__Gte-Pnoitcnufyxor {
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
