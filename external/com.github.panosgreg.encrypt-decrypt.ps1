<#
.DESCRIPTION
Encryption & Decryption using native .NET functions

This is Symetrical encryption. Which means the same key is used to both encrypt and decrypt.

The encryption method is based on AES 256bit.

The major difference between this option and the ConvertFrom/To-SecureString functions
is that this way produces much smaller encrypted files.
I have not compared the 2 options in regards to performance though, as-in which one is faster.

.LINK
Url: <https://github.com/PanosGreg>
Retrieved: 2024_10_03

.LINK
Url: <https://www.reddit.com/r/PowerShell/comments/tk1y8q/encrypt_a_file_with_a_keypassword/>
Retrieved: 2024_10_03
#>

function Protect-String {
    [cmdletbinding()]
    param (
        [ValidateLength(32,32)]
        [string]$Key,

        [Parameter(ValueFromPipeline = $true)]
        [string]$InputString
    )

    $ByteKey              = [Byte[]][Char[]]$Key
    $bytes                = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $aesManaged           = [System.Security.Cryptography.AesManaged]::new()
    $aesManaged.Mode      = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding   = [System.Security.Cryptography.PaddingMode]::PKCS7
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize   = 256
    $aesManaged.Key       = $ByteKey
    $aesManaged.IV        = $ByteKey[0 .. 15]
    $encryptor            = $aesManaged.CreateEncryptor()
    $encryptedData        = $encryptor.TransformFinalBlock($bytes, 0, $bytes.Length)
    $EncryptedString      = [System.Convert]::ToBase64String($encryptedData)
    $aesManaged.Dispose()

    Write-Output $EncryptedString
}


<#
.DESCRIPTION
Encryption & Decryption using native .NET functions

This is Symetrical encryption. Which means the same key is used to both encrypt and decrypt.

The encryption method is based on AES 256bit.

The major difference between this option and the ConvertFrom/To-SecureString functions
is that this way produces much smaller encrypted files.
I have not compared the 2 options in regards to performance though, as-in which one is faster.

.LINK
Url: <https://github.com/PanosGreg>
Retrieved: 2024_10_03

.LINK
Url: <https://www.reddit.com/r/PowerShell/comments/tk1y8q/encrypt_a_file_with_a_keypassword/>
Retrieved: 2024_10_03
#>
function Unprotect-String {
    [cmdletbinding()]
    param (
        [ValidateLength(32,32)]
        [string]$Key,

        [Parameter(ValueFromPipeline = $true)]
        [string]$InputString
    )

    $ByteKey              = [Byte[]][Char[]]$Key
    $bytes                = [System.Convert]::FromBase64String($InputString)
    $aesManaged           = [System.Security.Cryptography.AesManaged]::new()
    $aesManaged.Mode      = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding   = [System.Security.Cryptography.PaddingMode]::PKCS7
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize   = 256
    $aesManaged.Key       = $ByteKey
    $aesManaged.IV        = $ByteKey[0 .. 15]
    $decryptor            = $aesManaged.CreateDecryptor()
    $unencryptedData      = $decryptor.TransformFinalBlock($bytes, 0, $bytes.Length)
    $DecryptedString      = [Text.Encoding]::UTF8.GetString($unencryptedData).Trim([char]0)
    $aesManaged.Dispose()

    Write-Output $DecryptedString
}

