. "$PsScriptRoot/../external/com.github.panosgreg.encrypt-decrypt.ps1"
. "$PsScriptRoot/../script/Combinator.ps1"

<#
Tags: protect encrypt
#>

function ConvertTo-ProtectedKey {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $InputString
    )

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $hash = $sha256.ComputeHash($bytes)
    $hashString = -join ($hash | foreach { "{0:x2}" -f $_ })
    $hashString.Substring(0, 32)  # Truncate to 32 characters
}

function ConvertFrom-ProtectedKey {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [SecureString]
        $InputString
    )

    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($InputString)

    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}

function Read-ProtectedString {
    Param(
        [String[]]
        $InputString
    )

    Begin {
        $content = @()
    }

    Process {
        $content += @($InputString)
    }

    End {
        $key = Read-Host `
            -Prompt "Password" `
            -AsSecureString |
            ConvertFrom-ProtectedKey |
            ConvertTo-ProtectedKey

        $content |
            Out-String |
            Unprotect-String -Key $key
    }
}

function New-ProtectedKey {
    Param(
        [String]
        $Prompt
    )

    Read-Host `
        -Prompt $Prompt `
        -AsSecureString |
        ConvertFrom-ProtectedKey |
        ConvertTo-ProtectedKey
}

function Unprotect-Object {
    Param(
        [String]
        $Query
    )

    $key = New-ProtectedKey `
        -Prompt "Password"

    try {
        $locations = Get-Item "$PsScriptRoot/../res/setting" |
            Get-Content |
            Out-String |
            Unprotect-String -Key $key |
            ConvertFrom-Json |
            foreach { $_.Location }
    }
    catch {
        Write-Error "No data could be found using that password"
        return
    }

    $locations |
        foreach {
            $_.Where |
                ConvertTo-PsPath |
                Get-Item |
                Get-Content |
                Out-String |
                Unprotect-String -Key $key |
                ConvertFrom-Json
        } |
        foreach {
            $_.Definition
        } |
        where {
            $_.Name -eq $Query
        } |
        foreach {
            $_.Description
        }
}

