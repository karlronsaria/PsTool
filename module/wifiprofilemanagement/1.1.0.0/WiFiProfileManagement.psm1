$script:localizedData = Import-LocalizedData -BaseDirectory "$PSScriptRoot\en-US" -FileName WiFiProfileManagement.strings.psd1

<#
    .SYNOPSIS
        Attempts to connect to a specific network.
    .PARAMETER ProfileName
        The name of the profile to be connected. Profile names are case-sensitive.
    .PARAMETER ConnectionMode
        Specifies the mode of the connection. Valid values are Profile,TemporaryProfile,DiscoveryProfile,DiscoveryUnsecure, and Auto.
    .PARAMETER Dot11BssType
        A value that indicates the BSS type of the network. If a profile is provided, this BSS type must be the same as the one in the profile.
    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'
    .EXAMPLE
        PS C:\>Connect-WiFiProfile -ProfileName FreeWiFi

        This example connects to the FreeWiFi profile which is already saved on the local machine.
    .EXAMPLE
        PS C:\> $password = Read-Host -AsSecureString
        ************

        PS C:\> New-WiFiProfile -ProfileName MyNetwork -ConnectionMode auto -Authentication WPA2PSK -Encryption AES -Password $password

        The operation was successful.
        PS C:\> Connect-WiFiProfile -ProfileName MyNetwork

        This example demonstrates how to create a WiFi profile and then connect to it.
    .NOTES
        https://msdn.microsoft.com/en-us/library/windows/desktop/ms706613(v=vs.85).aspx
#>
function Connect-WiFiProfile
{
    [OutputType([void])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProfileName,

        [Parameter()]
        [ValidateSet('Profile', 'TemporaryProfile', 'DiscoverySecure', 'DiscoveryUnsecure', 'Auto')]
        [System.String]
        $ConnectionMode = 'Profile',

        [Parameter()]
        [ValidateSet('Any', 'Independent', 'Infrastructure')]
        [System.String]
        $Dot11BssType = 'Any',

        [Parameter()]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi'
    )

    begin
    {
        $interfaceGuid = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName -ErrorAction Stop
    }
    process
    {
        try
        {
            $clientHandle = New-WiFiHandle

            $connectionParameterList = New-WiFiConnectionParameter -ProfileName $ProfileName -ConnectionMode $ConnectionMode -Dot11BssType $Dot11BssType

            Invoke-WlanConnect -ClientHandle $clientHandle -InterfaceGuid $interfaceGuid -ConnectionParameterList $connectionParameterList
        }
        catch
        {
            Write-Error $PSItem
        }
        finally
        {
            if ($clientHandle)
            {
                Remove-WiFiHandle -ClientHandle $clientHandle
            }
        }
    }
}

<#
    .SYNOPSIS
        Retrieves the list of available networks on a wireless LAN interface.
    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'
    .EXAMPLE
        PS C:\>Get-WiFiAvailableNetwork

        SSID         SignalStength SecurityEnabled  dot11DefaultAuthAlgorithm dot11DefaultCipherAlgorithm
        ----         ------------- ---------------  ------------------------- ---------------------------
                                63            True   DOT11_AUTH_ALGO_RSNA_PSK      DOT11_CIPHER_ALGO_CCMP
        gogoinflight            63           False DOT11_AUTH_ALGO_80211_OPEN      DOT11_CIPHER_ALGO_NONE
    .NOTES
        https://msdn.microsoft.com/en-us/library/windows/desktop/ms706749(v=vs.85).aspx
#>
function Get-WiFiAvailableNetwork
{
    [CmdletBinding()]
    [OutputType([WiFi.ProfileManagement+WLAN_AVAILABLE_NETWORK])]
    param
    (
        [Parameter()]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi'
    )

    $interfaceGUID = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName -ErrorAction Stop
    $clientHandle = New-WiFiHandle
    $networkPointer = 0
    $flag = 0

    try
    {
        $result = [WiFi.ProfileManagement]::WlanGetAvailableNetworkList(
            $clientHandle,
            $interfaceGUID,
            $flag,
            [IntPtr]::zero,
            [ref] $networkPointer
        )

        if ( $result -ne 0 )
        {
            $errorMessage = Format-Win32Exception -ReturnCode $result
            throw $($script:localizedData.ErrorGetAvailableNetworkList -f $errorMessage)
        }

        $availableNetworks = [WiFi.ProfileManagement+WLAN_AVAILABLE_NETWORK_LIST]::new($networkPointer)

        foreach ($network in $availableNetworks.wlanAvailableNetwork)
        {
            [WiFi.ProfileManagement+WLAN_AVAILABLE_NETWORK] $network
        }
    }
    catch
    {
        Write-Error $PSItem
    }
    finally
    {
        Invoke-WlanFreeMemory -Pointer $networkPointer

        if ($clientHandle)
        {
            Remove-WiFiHandle -ClientHandle $clientHandle
        }
    }
}

<#
    .SYNOPSIS
        Lists the wireless profiles and their configuration settings.
    .PARAMETER ProfileName
        The name of the WiFi profile.
    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'
    .PARAMETER ClearKey
        Specifies if the password of the profile is to be returned.
    .EXAMPLE
        PS C:\>Get-WiFiProfile -ProfileName TestWiFi

        SSIDName       : TestWiFi
        ConnectionMode : auto
        Authentication : WPA2PSK
        Encryption     : AES
        Password       :

        Get the WiFi profile information on wireless profile TestWiFi

    .EXAMPLE 
        PS C:\>Get-WiFiProfile -ProfileName TestWiFi -CLearKey

        SSIDName       : TestWiFi
        ConnectionMode : auto
        Authentication : WPA2PSK
        Encryption     : AES
        Password       : password1

        This examples shows the use of the ClearKey switch to return the WiFi profile password.

    .EXAMPLE
        PS C:\>Get-WiFiProfile | where {$PSItem.ConnectionMode -eq 'auto' -and $PSItem.Authentication -eq 'open'}

        This example shows how to find WiFi profiles with insecure connection settings.
#>
function Get-WiFiProfile
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter(Position = 0)]
        [System.String[]]
        $ProfileName,

        [Parameter()]
        [System.String]
        $WiFiAdapterName,

        [Parameter()]
        [Switch]
        $ClearKey
    )

    try
    {
        $profileListPointer = 0

        if (!$WiFiAdapterName)
        {
            $interfaceGuids = (Get-WiFiInterface).Guid
        }
        else
        { 
            $interfaceGuids = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName
        }

        $clientHandle = New-WiFiHandle

        if ($ClearKey)
        {
            $wlanProfileFlags = 13
        }
        else
        {
            $wlanProfileFlags = 0
        }

        if (!$ProfileName)
        {
            foreach ($interfaceGUID in $interfaceGuids)
            {
                [void] [WiFi.ProfileManagement]::WlanGetProfileList(
                    $clientHandle,
                    $interfaceGUID,
                    [IntPtr]::zero,
                    [ref] $profileListPointer
                )
                $wiFiProfileList = [WiFi.ProfileManagement+WLAN_PROFILE_INFO_LIST]::new($profileListPointer)
                $ProfileName = ($wiFiProfileList.ProfileInfo).strProfileName
            }
        }

        foreach ($wiFiProfile in $ProfileName)
        {
            foreach ($interfaceGUID in $interfaceGuids)
            {
                Get-WiFiProfileInfo -ProfileName $wiFiProfile -InterfaceGuid $interfaceGUID -ClientHandle $clientHandle -WlanProfileFlags $wlanProfileFlags
            }
        }
    }
    catch
    {
        Write-Error $PSItem
    }
    finally
    {
        if ($clientHandle)
        {
            Remove-WiFiHandle -ClientHandle $clientHandle
        }
    }
}

<#
    .SYNOPSIS
        Creates the content of a specified wireless profile.
    .DESCRIPTION
        Creates the content of a wireless profile by calling the WlanSetProfile native function but with the override parameter set to false. 
    .PARAMETER ProfileName
        The name of the wireless profile to be created. Profile names are case sensitive.
    .PARAMETER ConnectionMode
        Indicates whether connection to the wireless LAN should be automatic ("auto") or initiated ("manual") by user.
    .PARAMETER Authentication
        Specifies the authentication method to be used to connect to the wireless LAN.
    .PARAMETER Encryption
        Sets the data encryption to use to connect to the wireless LAN.
    .PARAMETER Password
        The network key or passphrase of the wireless profile in the form of a secure string.
    .PARAMETER ConnectHiddenSSID
        Specifies whether the profile can connect to networks which does not broadcast SSID. The default is false.
    .PARAMETER EAPType
        (Only 802.1X) Specifies the type of 802.1X EAP. You can select "PEAP"(aka MSCHAPv2) or "TLS".
    .PARAMETER ServerNames
        (Only 802.1X) Specifies the server that will be connect to validate certification.
    .PARAMETER TrustedRootCA
        (Only 802.1X) Specifies the certificate thumbprint of the Trusted Root CA.
    .PARAMETER XmlProfile
        The XML representation of the profile.
    .EXAMPLE
        PS C:\>$password = Read-Host -AsSecureString
        **********

        PS C:\>New-WiFiProfile -ProfileName MyNetwork -ConnectionMode auto -Authentication WPA2PSK -Encryption AES -Password $password 

        This examples shows how to create a wireless profile by using the individual parameters.
    .EXAMPLE
        PS C:\>New-WiFiProfile -ProfileName OneXNetwork -Authentication WPA2 -Encryption AES -EAPType PEAP -TrustedRootCA '041101cca5b336a9c6e50d173489f5929e1b4b00'

        This examples shows how to create a 802.1X wireless profile by using the individual parameters.
    .EXAMPLE
        PS C:\>$templateProfileXML = @"
        <?xml version="1.0"?>
        <WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
            <name>MyNetwork</name>
            <SSIDConfig>
                <SSID>            
                    <name>MyNetwork</name>
                </SSID>
            </SSIDConfig>
            <connectionType>ESS</connectionType>
            <connectionMode>manual</connectionMode>
            <MSM>
                <security>
                    <authEncryption>
                        <authentication>WPA2PSK</authentication>
                        <encryption>AES</encryption>
                        <useOneX>false</useOneX>
                    </authEncryption>
                    <sharedKey>
                        <keyType>passPhrase</keyType>
                        <protected>false</protected>
                        <keyMaterial>password1</keyMaterial>
                    </sharedKey>
                </security>
            </MSM>
        </WLANProfile>
        "@

        PS C:\>New-WiFiProfile -XmlProfile $templateProfileXML

        This example demonstrates how to update a wireless profile with the XmlProfile parameter.
    .NOTES
        https://msdn.microsoft.com/en-us/library/windows/desktop/ms706795(v=vs.85).aspx
        https://msdn.microsoft.com/en-us/library/windows/desktop/ms707381(v=vs.85).aspx
#>
function New-WiFiProfile
{
    [CmdletBinding(DefaultParameterSetName = 'UsingArguments')]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'UsingArguments')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'UsingArgumentsWithEAP')]
        [Alias('SSID', 'Name')]
        [System.String]
        $ProfileName,

        [Parameter(ParameterSetName = 'UsingArguments')]
        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [ValidateSet('manual', 'auto')]
        [System.String]
        $ConnectionMode = 'auto',

        [Parameter(ParameterSetName = 'UsingArguments')]
        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [ValidateSet('open', 'shared', 'WPA', 'WPAPSK', 'WPA2', 'WPA2PSK', 'WPA3SAE', 'WPA3ENT192', 'OWE')]
        [System.String]
        $Authentication = 'WPA2PSK',

        [Parameter(ParameterSetName = 'UsingArguments')]
        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [ValidateSet('none', 'WEP', 'TKIP', 'AES', 'GCMP256')]
        [System.String]
        $Encryption = 'AES',

        [Parameter(ParameterSetName = 'UsingArguments')]
        [System.Security.SecureString]
        $Password,

        [Parameter(ParameterSetName = 'UsingArguments')]
        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [System.Boolean]
        $ConnectHiddenSSID = $false,

        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [ValidateSet('PEAP', 'TLS')]
        [System.String]
        $EAPType,

        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [AllowEmptyString()]
        [System.String]
        $ServerNames = '',

        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [System.String]
        $TrustedRootCA,

        [Parameter()]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi',

        [Parameter(Mandatory = $true, ParameterSetName = 'UsingXml')]
        [System.String]
        $XmlProfile,

        [Parameter(DontShow = $true)]
        [System.Boolean]
        $Overwrite = $false
    )

    try
    {
        $interfaceGuid = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName -ErrorAction Stop
        $clientHandle = New-WiFiHandle
        $flags = 0
        $reasonCode = [IntPtr]::Zero

        if ($XmlProfile)
        {
            $profileXML = $XmlProfile
        }
        else
        {
            $newProfileParameters = @{
                ProfileName       = $ProfileName
                ConnectionMode    = $ConnectionMode
                Authentication    = $Authentication
                Encryption        = $Encryption
                Password          = $Password
                ConnectHiddenSSID = $ConnectHiddenSSID
                EAPType           = $EAPType
                ServerNames       = $ServerNames
                TrustedRootCA     = $TrustedRootCA
            }

            $profileXML = New-WiFiProfileXml @newProfileParameters
        }

        $profilePointer = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($profileXML)

        $returnCode = [WiFi.ProfileManagement]::WlanSetProfile(
            $clientHandle,
            [ref] $interfaceGuid,
            $flags,
            $profilePointer,
            [IntPtr]::Zero,
            $Overwrite,
            [IntPtr]::Zero,
            [ref]$reasonCode
        )

        $returnCodeMessage = Format-Win32Exception -ReturnCode $returnCode
        $reasonCodeMessage = Format-WiFiReasonCode -ReasonCode $reasonCode

        if ($returnCode -eq 0)
        {
            Write-Verbose -Message $returnCodeMessage
        }
        else
        {
            throw $returnCodeMessage
        }

        Write-Verbose -Message $reasonCodeMessage
    }
    catch
    {
        Write-Error $PSItem
    }
    finally
    {
        if ($clientHandle)
        {
            Remove-WiFiHandle -ClientHandle $clientHandle
        }
    }
}

<#
    .SYNOPSIS
        Deletes a WiFi profile.
    .PARAMETER ProfileName
        The name of the profile to be deleted. Profile names are case-sensitive.
    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'
    .EXAMPLE
    PS C:\>Remove-WiFiProfile -ProfileName FreeWiFi

    This examples deletes the FreeWiFi profile.
#>
function Remove-WiFiProfile
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    Param 
    (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String[]]
        $ProfileName,

        [Parameter(Position = 1)]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi'
    )

    begin
    {
        $interfaceGUID = Get-WiFiInterfaceGuid -ErrorAction Stop
    }
    process
    {
        try
        {
            $clientHandle = New-WiFiHandle

            foreach ($wiFiProfile in $ProfileName)
            {
                if ($PSCmdlet.ShouldProcess("$($script:localizedData.ShouldProcessDelete -f $WiFiProfile)"))
                {
                    $deleteProfileResult = [WiFi.ProfileManagement]::WlanDeleteProfile(
                        $clientHandle,
                        $interfaceGUID,
                        $wiFiProfile,
                        [IntPtr]::Zero
                    )

                    $deleteProfileResultMessage = Format-Win32Exception -ReturnCode $deleteProfileResult

                    if ($deleteProfileResult -ne 0)
                    {
                        Write-Error -Message ($script:localizedData.ErrorDeletingProfile -f $deleteProfileResultMessage)
                    }
                    else
                    {
                        Write-Verbose -Message $deleteProfileResultMessage
                    }

                }
            }
        }
        catch
        {
            Write-Error $PSItem
        }
        finally
        {
            if ($clientHandle)
            {
                Remove-WiFiHandle -ClientHandle $clientHandle
            }
        }
    }
}

<#
    .SYNOPSIS
        Requests a scan for available wifi networks on the indicated interface.
        The scan is requested by calling the WlanScan function in the WlanApi

    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'

    .EXAMPLE
        PS C:\>Search-WiFiNetwork WiFiAdapterName WiFi

        This examples will search for WiFi netowrks on the WiFi adapter.
#>
function Search-WiFiNetwork
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi'
    )

    try
    {
        if (!$WiFiAdapterName)
        {
            $interfaceGuids = (Get-WiFiInterface).Guid
        }
        else
        { 
            $interfaceGuids = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName
        }

        $clientHandle = New-WiFiHandle

        foreach ($interfaceGuid in $interfaceGuids)
        {
            $resultCode = [WiFi.ProfileManagement]::WlanScan(
                $clientHandle,
                [ref] $interfaceGuid,
                [IntPtr]::zero,
                [IntPtr]::zero,
                [IntPtr]::zero
            )

            if ($resultCode -ne 0)
            {
                $resultCode
            }
        }
    }
    catch
    {
        Write-Error $PSItem
    }
    finally
    {
        if ($clientHandle)
        {
            Remove-WiFiHandle -ClientHandle $clientHandle
        }
    }
}

<#
    .SYNOPSIS
        Toggles the software wifi radio state on/off.

    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'

    .PARAMETER State
        Specifies the state of the wifi radio.  Valid values are on/off.

    .EXAMPLE
        Set-WiFiInterface -State On

        In this example the wifi radio is being turned on.

    .EXAMPLE
        Set-WiFiInterface -State Off

        In this example the wifi radio is being turned off.
#>
function Set-WiFiInterface
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi',

        [Parameter(Mandatory = $true)]
        [ValidateSet('On','Off')]
        [string]
        $State
    )

    try
    {
        if (!$WiFiAdapterName)
        {
            $interfaceGuids = (Get-WiFiInterface).Guid
        }
        else
        {
            $interfaceGuids = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName
        }

        $clientHandle = New-WiFiHandle

        $radioStatePtr = [System.IntPtr]::new(0L)
        $radioState = [WiFi.ProfileManagement+WlanPhyRadioState]::new()
        $radioState.dot11SoftwareRadioState = [WiFi.ProfileManagement+Dot11RadioState]::$State
        $radioState.dot11HardwareRadioState = [WiFi.ProfileManagement+Dot11RadioState]::$State
        $opCode = [WiFi.ProfileManagement+WLAN_INTF_OPCODE]::wlan_intf_opcode_radio_state
        $radioStateSize = [System.Runtime.InteropServices.Marshal]::SizeOf($radioState)
        $radioStatePtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($radioStateSize)

        [System.Runtime.InteropServices.Marshal]::StructureToPtr($radioState, $radioStatePtr, $false)


        foreach ($interfaceGuid in $interfaceGuids)
        {
            $resultCode = [WiFi.ProfileManagement]::WlanSetInterface(
                $clientHandle,
                [ref] $interfaceGuid,
                $opCode,
                [System.Runtime.InteropServices.Marshal]::SizeOf([System.Type]([WiFi.ProfileManagement+WlanPhyRadioState])),
                $radioStatePtr,
                [IntPtr]::zero
            )

            if ($resultCode -ne 0)
            {
                $resultCode
            }
        }
    }
    catch
    {
        Write-Error -Exception $PSItem
    }
    finally
    {
        if ($clientHandle)
        {
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($radioStatePtr)
            Remove-WiFiHandle -ClientHandle $clientHandle
        }
    }
}

<#
    .SYNOPSIS
        Sets the content of a specified wireless profile.
    .DESCRIPTION
        Calls the WlanSetProfile native function with override parameter set to true.
    .PARAMETER ProfileName
        The name of the wireless profile to be updated. Profile names are case sensitive.
    .PARAMETER ConnectionMode
        Indicates whether connection to the wireless LAN should be automatic ("auto") or initiated ("manual") by user.
    .PARAMETER Authentication
        Specifies the authentication method to be used to connect to the wireless LAN.
    .PARAMETER Encryption
        Sets the data encryption to use to connect to the wireless LAN.
    .PARAMETER Password
        The network key or passphrase of the wireless profile in the form of a secure string.
    .PARAMETER ConnectHiddenSSID
        Specifies whether the profile can connect to networks which does not broadcast SSID. The default is false.
    .PARAMETER EAPType
        (Only 802.1X) Specifies the type of 802.1X EAP. You can select "PEAP"(aka MSCHAPv2) or "TLS".
    .PARAMETER ServerNames
        (Only 802.1X) Specifies the server that will be connect to validate certification.
    .PARAMETER TrustedRootCA
        (Only 802.1X) Specifies the certificate thumbprint of the Trusted Root CA.
    .PARAMETER XmlProfile
        The XML representation of the profile.
    .EXAMPLE
        PS C:\>$password = Read-Host -AsSecureString
        **********

        PS C:\>Set-WiFiProfile -ProfileName MyNetwork -ConnectionMode auto -Authentication WPA2PSK -Encryption AES -Password $password 

        This examples shows how to update or create a wireless profile by using the individual parameters.
    .EXAMPLE
        PS C:\>$templateProfileXML = @"
        <?xml version="1.0"?>
        <WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
            <name>MyNetwork</name>
            <SSIDConfig>
                <SSID>            
                    <name>MyNetwork</name>
                </SSID>
            </SSIDConfig>
            <connectionType>ESS</connectionType>
            <connectionMode>manual</connectionMode>
            <MSM>
                <security>
                    <authEncryption>
                        <authentication>WPA2PSK</authentication>
                        <encryption>AES</encryption>
                        <useOneX>false</useOneX>
                    </authEncryption>
                    <sharedKey>
                        <keyType>passPhrase</keyType>
                        <protected>false</protected>
                        <keyMaterial>password1</keyMaterial>
                    </sharedKey>
                </security>
            </MSM>
        </WLANProfile>
        "@

        PS C:\>Set-WiFiProfile -XmlProfile $templateProfileXML

        This example demonstrates how to update a wireless profile with the XmlProfile parameter.
    .NOTES
        https://msdn.microsoft.com/en-us/library/windows/desktop/ms706795(v=vs.85).aspx
        https://msdn.microsoft.com/en-us/library/windows/desktop/ms707381(v=vs.85).aspx
#>
function Set-WiFiProfile
{
    [CmdletBinding(DefaultParameterSetName = 'UsingArguments')]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'UsingArguments')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'UsingArgumentsWithEAP')]
        [Alias('SSID', 'Name')]
        [System.String]
        $ProfileName,

        [Parameter(ParameterSetName = 'UsingArguments')]
        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [ValidateSet('manual', 'auto')]
        [System.String]
        $ConnectionMode = 'auto',

        [Parameter(ParameterSetName = 'UsingArguments')]
        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [ValidateSet('open', 'shared', 'WPA', 'WPAPSK', 'WPA2', 'WPA2PSK', 'WPA3SAE', 'WPA3ENT192', 'OWE')]
        [System.String]
        $Authentication = 'WPA2PSK',

        [Parameter(ParameterSetName = 'UsingArguments')]
        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [ValidateSet('none', 'WEP', 'TKIP', 'AES', 'GCMP256')]
        [System.String]
        $Encryption = 'AES',

        [Parameter(ParameterSetName = 'UsingArguments')]
        [System.Security.SecureString]
        $Password,

        [Parameter(ParameterSetName = 'UsingArguments')]
        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [System.Boolean]
        $ConnectHiddenSSID = $false,

        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [ValidateSet('PEAP', 'TLS')]
        [System.String]
        $EAPType,

        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [AllowEmptyString()]
        [System.String]
        $ServerNames = '',

        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [System.String]
        $TrustedRootCA,

        [Parameter()]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi',

        [Parameter(Mandatory = $true, ParameterSetName = 'UsingXml')]
        [System.String]
        $XmlProfile
    )

    New-WiFiProfile @PSBoundParameters -Overwrite $true
}

<#
    .SYNOPSIS
        An internal function to format the reason code returned by WlanSetProfile
    .PARAMETER ReasonCode
        A value that indicates why the profile failed.
#>
function Format-WiFiReasonCode
{
    [OutputType([System.String])]
    [Cmdletbinding()]
    param
    (
        [Parameter()]
        [System.IntPtr]
        $ReasonCode
    )

    $stringBuilder = New-Object -TypeName Text.StringBuilder
    $stringBuilder.Capacity = 1024

    $result = [WiFi.ProfileManagement]::WlanReasonCodeToString(
        $ReasonCode.ToInt32(),
        $stringBuilder.Capacity,
        $stringBuilder,
        [IntPtr]::zero
    )

    if ($result -ne 0)
    {
        $errorMessage = Format-Win32Exception -ReturnCode $result
        Write-Error -Message ($script:localizedData.ErrorReasonCode -f $errorMessage)
    }

    return $stringBuilder.ToString()
}

<#
    .SYNOPSIS
        Returns the exception message from a Win32 API call
    .PARAMETER ReturnCode
        Specifies the return code that will be resolved to an error message.
#>
function Format-Win32Exception
{
    [OutputType([System.String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $ReturnCode
    )

    return [System.ComponentModel.Win32Exception]::new($ReturnCode).Message
}

<#
    .SYNOPSIS
        Lists the wireless interfaces and their state.
#>
function Get-WiFiInterface
{
    [CmdletBinding()]
    [OutputType([WiFi.ProfileManagement+WLAN_INTERFACE_INFO])]
    param ()

    $interfaceListPtr = 0
    $clientHandle = New-WiFiHandle

    try
    {
        [void] [WiFi.ProfileManagement]::WlanEnumInterfaces($clientHandle, [IntPtr]::zero, [ref] $interfaceListPtr)
        $wiFiInterfaceList = [WiFi.ProfileManagement+WLAN_INTERFACE_INFO_LIST]::new($interfaceListPtr)

        foreach ($wlanInterfaceInfo in $wiFiInterfaceList.wlanInterfaceInfo)
        {
            [WiFi.ProfileManagement+WLAN_INTERFACE_INFO] $wlanInterfaceInfo
        }
    }
    catch
    {
        Write-Error $PSItem
    }
    finally
    {
        Remove-WiFiHandle -ClientHandle $clientHandle
    }
}

<#
    .SYNOPSIS
        Retrieves the guid of the network interface.
    .PARAMETER WiFiAdapterName
        The name of the wireless network adapter.
#>
function Get-WiFiInterfaceGuid
{
    [CmdletBinding()]
    [OutputType([System.Guid])]
    param 
    (
        [Parameter()]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi'
    )
    
    $osVersion = [Environment]::OSVersion.Version

    if ($osVersion -ge ([Version] 6.2))
    {
        $interfaceGuid = (Get-NetAdapter -Name $WiFiAdapterName -ErrorAction SilentlyContinue).interfaceguid
    }
    else
    {
        $wifiAdapterInfo = Get-WmiObject -Query "select Name, NetConnectionID from Win32_NetworkAdapter where NetConnectionID = '$WiFiAdapterName'"
        $interfaceGuid = (Get-WmiObject -Query "select SettingID from Win32_NetworkAdapterConfiguration where Description = '$($wifiAdapterInfo.Name)'").SettingID
    }

    if (-not ($interfaceGuid -as [System.Guid]))
    {
        Write-Error $($script:localizedData.ErrorWiFiInterfaceNotFound)
    }

    return [System.Guid]$interfaceGuid
}

<#
    .SYNOPSIS
        Retrieves the information of a WiFi profile.
    .PARAMETER ProfileName
        The name of the WiFi profile. Profile names are case-sensitive.
    .PARAMETER InterfaceGuid
        Specifies the Guid of the wireless network card. This is required by the native WiFi functions.
    .PARAMETER ClientHandle
        Specifies the handle used by the native WiFi functions.
    .PARAMETER WlanProfileFlags
        A pointer to the address location used to provide additional information about the request.
#>
function Get-WiFiProfileInfo
{
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $ProfileName,

        [Parameter()]
        [System.Guid]
        $InterfaceGuid,

        [Parameter()]
        [System.IntPtr]
        $ClientHandle,

        [System.Int16]
        $WlanProfileFlags
    )
    
    begin
    {
        [String] $pstrProfileXml = $null
        $wlanAccess = 0
        $WlanProfileFlagsInput = $WlanProfileFlags
    }
    process
    {
        $result = [WiFi.ProfileManagement]::WlanGetProfile(
            $ClientHandle,
            $InterfaceGuid,
            $ProfileName,
            [IntPtr]::Zero,
            [ref] $pstrProfileXml,
            [ref] $WlanProfileFlags,
            [ref] $wlanAccess
        )

        if ($result -ne 0)
        {
            $errorMessage = Format-Win32Exception -ReturnCode $result
            throw $($script:localizedData.ErrorGettingProfile -f $errorMessage)
        }

        $wlanProfile = [xml] $pstrProfileXml

        #Parse password
        if ($WlanProfileFlagsInput -eq 13)
        {
            $password = $wlanProfile.WLANProfile.MSM.security.sharedKey.keyMaterial
        }
        else
        {
            $password = $null
        }

        # Parse nonBroadcast flag
        if ([bool]::TryParse($wlanProfile.WLANProfile.SSIDConfig.nonBroadcast, [ref] $null))
        {
            $connectHiddenSSID = [bool]::Parse($wlanProfile.WLANProfile.SSIDConfig.nonBroadcast)
        }
        else
        {
            $connectHiddenSSID = $false
        }

        # Parse EAP type
        if ($wlanProfile.WLANProfile.MSM.security.authEncryption.useOneX -eq 'true')
        {
            switch ($wlanProfile.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.EapMethod.Type.InnerText)
            {
                '25'    #EAP-PEAP (MSCHAPv2)
                {
                    $eapType = 'PEAP'
                }

                '13'    #EAP-TLS
                {
                    $eapType = 'TLS'
                }

                Default
                {
                    $eapType = 'Unknown'
                }
            }
        }
        else
        {
            $eapType = $null
        }

        # Parse Validation Server Name
        if ($null -ne $eapType)
        {
            switch ($eapType)
            {
                'PEAP'
                { 
                    $serverNames = $wlanProfile.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.Eap.EapType.ServerValidation.ServerNames
                }

                'TLS'
                {
                    $node = $wlanProfile.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.SelectNodes("//*[local-name()='ServerNames']")
                    $serverNames = $node[0].InnerText
                }
            }
        }

        # Parse Validation TrustedRootCA
        if ($null -ne $eapType)
        {
            switch ($eapType)
            {
                'PEAP'
                { 
                    $trustedRootCa = ([string] ($wlanProfile.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.Eap.EapType.ServerValidation.TrustedRootCA -replace ' ', [string]::Empty)).ToLower()
                }

                'TLS'
                {
                    $node = $wlanProfile.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.SelectNodes("//*[local-name()='TrustedRootCA']")
                    $trustedRootCa = ([string] ($node[0].InnerText -replace ' ', [string]::Empty)).ToLower()
                }
            }
        }


        [WiFi.ProfileManagement+ProfileInfo]@{
            ProfileName       = $wlanProfile.WLANProfile.SSIDConfig.SSID.name
            ConnectionMode    = $wlanProfile.WLANProfile.connectionMode
            Authentication    = $wlanProfile.WLANProfile.MSM.security.authEncryption.authentication
            Encryption        = $wlanProfile.WLANProfile.MSM.security.authEncryption.encryption
            Password          = $password
            ConnectHiddenSSID = $connectHiddenSSID
            EAPType           = $eapType
            ServerNames       = $serverNames
            TrustedRootCA     = $trustedRootCa
            Xml               = $pstrProfileXml
        }
    }
    end
    {
        $xmlPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalAuto($pstrProfileXml)
        Invoke-WlanFreeMemory -Pointer $xmlPtr
    }
}

<#
    .SYNOPSIS
        Call the WlanConnect function to attempt to connect to a specific network
    .PARAMETER InterfaceGuid
        Specifies the Guid of the wireless network card. This is required by the native WiFi functions.
    .PARAMETER ClientHandle
        Specifies the handle used by the native WiFi functions.
    .PARAMETER ConnectionParameterList
        A WLAN_CONNECTION_PARAMETERS structure that specifies the parameters used when using the WlanConnect function.
#>
function Invoke-WlanConnect
{
    [OutputType([void])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.IntPtr]
        $ClientHandle,

        [Parameter(Mandatory = $true)]
        [System.Guid]
        $InterfaceGuid,

        [Parameter(Mandatory = $true)]
        [WiFi.ProfileManagement+WLAN_CONNECTION_PARAMETERS]
        $ConnectionParameterList
    )

    $result = [WiFi.ProfileManagement]::WlanConnect(
        $ClientHandle,
        [ref] $InterfaceGuid,
        [ref] $ConnectionParameterList,
        [IntPtr]::Zero
    )

    if ($result -ne 0)
    {
        $errorMessage = Format-Win32Exception -ReturnCode $result
        throw $($script:localizedData.ErrorWlanConnect -f $ConnectionParameterList.strProfile, $errorMessage)
    }
    else
    {
        $errorMessage = Format-Win32Exception -ReturnCode $result
        Write-Verbose -Message $($script:localizedData.SuccessWlanConnect -f $ConnectionParameterList.strProfile, $errorMessage)
    }
}

<#
    .SYNOPSIS
        Frees memory used by Native WiFi functions
    .PARAMETER Pointer
        Pointer to the memory to be freed.
#>
function Invoke-WlanFreeMemory
{
    [OutputType([void])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.IntPtr]
        $Pointer
    )

    try
    {
        [WiFi.ProfileManagement]::WlanFreeMemory($Pointer)
    }
    catch
    {
        throw $($script:localizedData.ErrorFreeMemory -f $errorMessage)
    }
}

<#
    .SYNOPSIS
        Creates a WLAN_CONNECTION_PARAMETERS structure that contains the required parameters when using the WlanConnect function
    .PARAMETER ProfileName
        The name of the profile to connect to. Profile names are case-sensitive.
    .PARAMETER ConnectionMode
        Specifies the mode of connection. Valid values are 'Profile', 'TemporaryProfile', 'DiscoverySecure', 'DiscoveryUnsecure', 'Auto'
    .PARAMETER Dot11BssType
        A value that indicates the BSS type of the network. If a profile is provided, this BSS type must be the same as the one in the profile.
    .NOTES
        https://msdn.microsoft.com/en-us/library/windows/desktop/ms706851(v=vs.85).aspx
#>
function New-WiFiConnectionParameter
{
    [OutputType([WiFi.ProfileManagement+WLAN_CONNECTION_PARAMETERS])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProfileName,

        [Parameter()]
        [ValidateSet('Profile', 'TemporaryProfile', 'DiscoverySecure', 'DiscoveryUnsecure', 'Auto')]
        [System.String]
        $ConnectionMode = 'Profile',

        [Parameter()]
        [ValidateSet('Any', 'Independent', 'Infrastructure')]
        [WiFi.ProfileManagement+DOT11_BSS_TYPE]
        $Dot11BssType = 'Any',

        [Parameter()]
        [WiFi.ProfileManagement+WlanConnectionFlag]
        $Flag = 'Default'
    )

    try
    {
        #region resolvers
        $connectionModeResolver = @{
            Profile           = 'wlan_connection_mode_profile'
            TemporaryProfile  = 'wlan_connection_mode_temporary_profile'
            DiscoverySecure   = 'wlan_connection_mode_discovery_secure'
            DiscoveryUnsecure = 'wlan_connection_mode_discovery_unsecure'
            Auto              = 'wlan_connection_mode_auto'
        }
        #endregion

        $connectionParameters = [WiFi.ProfileManagement+WLAN_CONNECTION_PARAMETERS]::new()
        $connectionParameters.strProfile = $ProfileName
        $connectionParameters.wlanConnectionMode = [WiFi.ProfileManagement+WLAN_CONNECTION_MODE]::$($connectionModeResolver[$ConnectionMode])
        $connectionParameters.dot11BssType = [WiFi.ProfileManagement+DOT11_BSS_TYPE]::$Dot11BssType
        $connectionParameters.dwFlags = [WiFi.ProfileManagement+WlanConnectionFlag]::$Flag
    }
    catch
    {
        throw $PSItem
    }

    return $connectionParameters
}

<#
    .SYNOPSIS
        Opens a WiFi handle
#>
function New-WiFiHandle
{    
    [CmdletBinding()]
    [OutputType([System.IntPtr])]
    param()

    $maxClient = 2
    [Ref]$negotiatedVersion = 0
    $clientHandle = [IntPtr]::zero

    $result = [WiFi.ProfileManagement]::WlanOpenHandle(
        $maxClient,
        [IntPtr]::Zero,
        $negotiatedVersion,
        [ref] $clientHandle
    )
    
    if ($result -eq 0)
    {
        return $clientHandle
    }
    else
    {
        $errorMessage = Format-Win32Exception -ReturnCode $result
        throw $($script:localizedData.ErrorOpeningHandle -f $errorMessage)
    }
}

$script:WiFiProfileXmlPersonal = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
  <name>{0}</name>
  <SSIDConfig>
    <SSID>
      <name>{0}</name>
    </SSID>
    <nonBroadcast>{1}</nonBroadcast>
  </SSIDConfig>
  <connectionType>ESS</connectionType>
  <connectionMode>{2}</connectionMode>
  <MSM>
    <security>
      <authEncryption>
        <authentication>{3}</authentication>
        <encryption>{4}</encryption>
        <useOneX>false</useOneX>
      </authEncryption>
      <sharedKey>
        <keyType>passPhrase</keyType>
        <protected>false</protected>
        <keyMaterial>{5}</keyMaterial>
      </sharedKey>
    </security>
  </MSM>
</WLANProfile>
"@

$script:WiFiProfileXmlEapPeap = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
  <name>{0}</name>
  <SSIDConfig>
    <SSID>
      <name>{0}</name>
    </SSID>
    <nonBroadcast>{1}</nonBroadcast>
  </SSIDConfig>
  <connectionType>ESS</connectionType>
  <connectionMode>{2}</connectionMode>
  <MSM>
    <security>
      <authEncryption>
        <authentication>{3}</authentication>
        <encryption>{4}</encryption>
        <useOneX>true</useOneX>
      </authEncryption>
      <PMKCacheMode>enabled</PMKCacheMode>
      <PMKCacheTTL>720</PMKCacheTTL>
      <PMKCacheSize>128</PMKCacheSize>
      <preAuthMode>disabled</preAuthMode>
      <OneX xmlns="http://www.microsoft.com/networking/OneX/v1">
        <authMode>machineOrUser</authMode>
        <EAPConfig>
          <EapHostConfig xmlns="http://www.microsoft.com/provisioning/EapHostConfig">
            <EapMethod>
              <Type xmlns="http://www.microsoft.com/provisioning/EapCommon">25</Type>
              <VendorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorId>
              <VendorType xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorType>
              <AuthorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</AuthorId>
            </EapMethod>
            <Config xmlns="http://www.microsoft.com/provisioning/EapHostConfig">
              <Eap xmlns="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1">
                <Type>25</Type>
                <EapType xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV1">
                  <ServerValidation>
                    <DisableUserPromptForServerValidation>false</DisableUserPromptForServerValidation>
                    <ServerNames></ServerNames>
                    <TrustedRootCA></TrustedRootCA>
                  </ServerValidation>
                  <FastReconnect>true</FastReconnect>
                  <InnerEapOptional>false</InnerEapOptional>
                  <Eap xmlns="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1">
                    <Type>26</Type>
                    <EapType xmlns="http://www.microsoft.com/provisioning/MsChapV2ConnectionPropertiesV1">
                      <UseWinLogonCredentials>false</UseWinLogonCredentials>
                    </EapType>
                  </Eap>
                  <EnableQuarantineChecks>false</EnableQuarantineChecks>
                  <RequireCryptoBinding>false</RequireCryptoBinding>
                  <PeapExtensions>
                    <PerformServerValidation xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV2">true</PerformServerValidation>
                    <AcceptServerName xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV2">true</AcceptServerName>
                    <PeapExtensionsV2 xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV2">
                      <AllowPromptingWhenServerCANotFound xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV3">true</AllowPromptingWhenServerCANotFound>
                    </PeapExtensionsV2>
                  </PeapExtensions>
                </EapType>
              </Eap>
            </Config>
          </EapHostConfig>
        </EAPConfig>
      </OneX>
    </security>
  </MSM>
</WLANProfile>
"@

$script:WiFiProfileXmlEapTls = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
  <name>{0}</name>
  <SSIDConfig>
    <SSID>
      <name>{0}</name>
    </SSID>
    <nonBroadcast>{1}</nonBroadcast>
  </SSIDConfig>
  <connectionType>ESS</connectionType>
  <connectionMode>{2}</connectionMode>
  <MSM>
    <security>
      <authEncryption>
        <authentication>{3}</authentication>
        <encryption>{4}</encryption>
        <useOneX>true</useOneX>
      </authEncryption>
      <PMKCacheMode>enabled</PMKCacheMode>
      <PMKCacheTTL>720</PMKCacheTTL>
      <PMKCacheSize>128</PMKCacheSize>
      <preAuthMode>disabled</preAuthMode>
      <OneX xmlns="http://www.microsoft.com/networking/OneX/v1">
        <authMode>machineOrUser</authMode>
        <EAPConfig>
          <EapHostConfig xmlns="http://www.microsoft.com/provisioning/EapHostConfig">
            <EapMethod>
              <Type xmlns="http://www.microsoft.com/provisioning/EapCommon">13</Type>
              <VendorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorId>
              <VendorType xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorType>
              <AuthorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</AuthorId>
            </EapMethod>
            <Config xmlns:baseEap="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1" xmlns:eapTls="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV1">
              <baseEap:Eap>
                <baseEap:Type>13</baseEap:Type>
                <eapTls:EapType>
                  <eapTls:CredentialsSource>
                    <eapTls:CertificateStore />
                  </eapTls:CredentialsSource>
                  <eapTls:ServerValidation>
                    <eapTls:DisableUserPromptForServerValidation>false</eapTls:DisableUserPromptForServerValidation>
                    <eapTls:ServerNames></eapTls:ServerNames>
                    <eapTls:TrustedRootCA></eapTls:TrustedRootCA>
                  </eapTls:ServerValidation>
                  <eapTls:DifferentUsername>false</eapTls:DifferentUsername>
                </eapTls:EapType>
              </baseEap:Eap>
            </Config>
          </EapHostConfig>
        </EAPConfig>
      </OneX>
    </security>
  </MSM>
</WLANProfile>
"@


<#
    .SYNOPSIS
        Create a string of XML that represents the wireless profile.
    .PARAMETER ProfileName
        The name of the wireless profile to be updated.  Profile names are case sensitive.
    .PARAMETER ConnectionMode
        Indicates whether connection to the wireless LAN should be automatic ("auto") or initiated ("manual") by user.
    .PARAMETER Authentication
        Specifies the authentication method to be used to connect to the wireless LAN.
    .PARAMETER Encryption
        Sets the data encryption to use to connect to the wireless LAN.
#>
function New-WiFiProfileXml
{
    [OutputType([System.String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $ProfileName,

        [Parameter()]
        [ValidateSet('manual', 'auto')]
        [System.String]
        $ConnectionMode = 'auto',

        [Parameter()]
        [System.String]
        $Authentication = 'WPA2PSK',

        [Parameter()]
        [System.String]
        $Encryption = 'AES',

        [Parameter()]
        [System.Security.SecureString]
        $Password,

        [Parameter()]
        [System.Boolean]
        $ConnectHiddenSSID = $false,

        [Parameter()]
        [System.String]
        $EAPType,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]
        $ServerNames = '',

        [Parameter()]
        [System.String]
        $TrustedRootCA
    )

    try
    {
        if ($Password)
        {
            $secureStringToBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
            $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($secureStringToBstr)
        }

        if ($EAPType -eq 'PEAP')
        {
            $profileXml = [xml] ($script:WiFiProfileXmlEapPeap -f $ProfileName, ([string] $ConnectHiddenSSID).ToLower(), $ConnectionMode, $Authentication, $Encryption)

            if ($ServerNames)
            {
                $profileXml.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.Eap.EapType.ServerValidation.ServerNames = $ServerNames
            }

            if ($TrustedRootCA)
            {
                [string]$formattedCaHash = $TrustedRootCA -replace '..', '$& '
                $profileXml.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.Eap.EapType.ServerValidation.TrustedRootCA = $formattedCaHash
            }
        }
        elseif ($EAPType -eq 'TLS')
        {
            $profileXml = [xml] ($script:WiFiProfileXmlEapTls -f $ProfileName, ([string] $ConnectHiddenSSID).ToLower(), $ConnectionMode, $Authentication, $Encryption)

            if ($ServerNames)
            {
                $node = $profileXml.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.SelectNodes("//*[local-name()='ServerNames']")
                $node[0].InnerText = $ServerNames
            }

            if ($TrustedRootCA)
            {
                [string]$formattedCaHash = $TrustedRootCA -replace '..', '$& '
                $node = $profileXml.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.SelectNodes("//*[local-name()='TrustedRootCA']")
                $node[0].InnerText = $formattedCaHash
            }
        }
        else
        {
            $profileXml = [xml] ($script:WiFiProfileXmlPersonal -f $ProfileName, ([string] $ConnectHiddenSSID).ToLower(), $ConnectionMode, $Authentication, $Encryption, $plainPassword)
            if (-not $plainPassword)
            {
                $null = $profileXml.WLANProfile.MSM.security.RemoveChild($profileXml.WLANProfile.MSM.security.sharedKey)
            }

            if ($Authentication -eq 'WPA3SAE'){
              # Set transition mode as true for WPA3-SAE
              $nsmg = [System.Xml.XmlNamespaceManager]::new($profileXml.NameTable)
              $nsmg.AddNamespace('WLANProfile', $profileXml.DocumentElement.GetAttribute('xmlns'))
              $refNode = $profileXml.SelectSingleNode('//WLANProfile:authEncryption', $nsmg)
              $xmlnode = $profileXml.CreateElement('transitionMode', 'http://www.microsoft.com/networking/WLAN/profile/v4')
              $xmlnode.InnerText = 'true'
              $null = $refNode.AppendChild($xmlnode)
            }
        }

        $profileXml.OuterXml
    }
    catch
    {
        throw $PSItem
    }
}

<#
    .SYNOPSIS
        Closes an open WiFi handle
    .Parameter ClientHandle
        Specifies the object that represents the open WiFi handle.
#>
function Remove-WiFiHandle
{
    [OutputType([void])]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.IntPtr]
        $ClientHandle
    )

    $result = [WiFi.ProfileManagement]::WlanCloseHandle($ClientHandle, [IntPtr]::zero)

    if ($result -eq 0)
    {
        Write-Verbose -Message ($script:localizedData.HandleClosed)
    }
    else
    {
        $errorMessage = Format-Win32Exception -ReturnCode $result
        throw $($script:localizedData.ErrorClosingHandle -f $errorMessage)
    }
}


$WlanGetProfileListSig = @'

[DllImport("wlanapi.dll")]
public static extern uint WlanOpenHandle(
    [In] UInt32 clientVersion,
    [In, Out] IntPtr pReserved,
    [Out] out UInt32 negotiatedVersion,
    [Out] out IntPtr clientHandle
);

[DllImport("Wlanapi.dll")]
public static extern uint WlanCloseHandle(
    [In] IntPtr ClientHandle,
    IntPtr pReserved
);

[DllImport("wlanapi.dll", SetLastError = true, CallingConvention=CallingConvention.Winapi)]
public static extern uint WlanGetProfileList(
    [In] IntPtr clientHandle,
    [In, MarshalAs(UnmanagedType.LPStruct)] Guid interfaceGuid,
    [In] IntPtr pReserved,
    [Out] out IntPtr profileList
);

[DllImport("wlanapi.dll")]
public static extern uint WlanGetProfile(
    [In]IntPtr clientHandle,
    [In, MarshalAs(UnmanagedType.LPStruct)] Guid interfaceGuid,
    [In, MarshalAs(UnmanagedType.LPWStr)] string profileName,
    [In, Out] IntPtr pReserved,
    [Out, MarshalAs(UnmanagedType.LPWStr)] out string pstrProfileXml,
    [In, Out, Optional] ref uint flags,
    [Out, Optional] out uint grantedAccess
);

[DllImport("wlanapi.dll")]
public static extern uint WlanDeleteProfile(
    [In]IntPtr clientHanle,
    [In, MarshalAs(UnmanagedType.LPStruct)] Guid interfaceGuid,
    [In, MarshalAs(UnmanagedType.LPWStr)] string profileName,
    [In, Out] IntPtr pReserved
);

[DllImport("wlanapi.dll", EntryPoint = "WlanFreeMemory")]
public static extern void WlanFreeMemory(
    [In] IntPtr pMemory
);

[DllImport("Wlanapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern uint WlanSetProfile(
    [In] IntPtr clientHanle,
    [In] ref Guid interfaceGuid,
    [In] uint flags,
    [In] IntPtr ProfileXml,
    [In, Optional] IntPtr AllUserProfileSecurity,
    [In] bool Overwrite,
    [In, Out] IntPtr pReserved,
    [In, Out]ref IntPtr pdwReasonCode
);

[DllImport("wlanapi.dll",SetLastError = true, CharSet = CharSet.Unicode)]
public static extern uint WlanReasonCodeToString(
    [In] uint reasonCode,
    [In] uint bufferSize,
    [In, Out] StringBuilder builder,
    [In, Out] IntPtr Reserved
);

[DllImport("Wlanapi.dll", SetLastError = true)]
public static extern uint WlanGetAvailableNetworkList(
    [In] IntPtr hClientHandle,
    [In, MarshalAs(UnmanagedType.LPStruct)] Guid interfaceGuid,
    [In] uint dwFlags,
    [In] IntPtr pReserved,
    [Out] out IntPtr ppAvailableNetworkList
);

[DllImport("Wlanapi.dll", SetLastError = true)]
public static extern uint WlanConnect(
    [In] IntPtr hClientHandle,
    [In] ref Guid interfaceGuid,
    [In] ref WLAN_CONNECTION_PARAMETERS pConnectionParameters,
    [In, Out] IntPtr pReserved
);

[StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)]
public struct WLAN_CONNECTION_PARAMETERS
{
    public WLAN_CONNECTION_MODE wlanConnectionMode;
    public string strProfile;
    public DOT11_SSID[] pDot11Ssid;
    public DOT11_BSSID_LIST[] pDesiredBssidList;
    public DOT11_BSS_TYPE dot11BssType;
    public uint dwFlags;
}

public struct DOT11_BSSID_LIST
{
    public NDIS_OBJECT_HEADER Header;
    public ulong uNumOfEntries;
    public ulong uTotalNumOfEntries;
    public IntPtr BSSIDs;
}

public struct NDIS_OBJECT_HEADER
{
    public byte Type;
    public byte Revision;
    public ushort Size;
}

public struct WLAN_PROFILE_INFO_LIST
{
    public uint dwNumberOfItems;
    public uint dwIndex;
    public WLAN_PROFILE_INFO[] ProfileInfo;

    public WLAN_PROFILE_INFO_LIST(IntPtr ppProfileList)
    {
        dwNumberOfItems = (uint)Marshal.ReadInt32(ppProfileList);
        dwIndex = (uint)Marshal.ReadInt32(ppProfileList, 4);
        ProfileInfo = new WLAN_PROFILE_INFO[dwNumberOfItems];
        IntPtr ppProfileListTemp = new IntPtr(ppProfileList.ToInt64() + 8);

        for (int i = 0; i < dwNumberOfItems; i++)
        {
            ppProfileList = new IntPtr(ppProfileListTemp.ToInt64() + i * Marshal.SizeOf(typeof(WLAN_PROFILE_INFO)));
            ProfileInfo[i] = (WLAN_PROFILE_INFO)Marshal.PtrToStructure(ppProfileList, typeof(WLAN_PROFILE_INFO));
        }
    }
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct WLAN_PROFILE_INFO
{
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
    public string strProfileName;
    public WlanProfileFlags ProfileFLags;
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct WLAN_AVAILABLE_NETWORK_LIST
{
    public uint dwNumberOfItems;
    public uint dwIndex;
    public WLAN_AVAILABLE_NETWORK[] wlanAvailableNetwork;
    public WLAN_AVAILABLE_NETWORK_LIST(IntPtr ppAvailableNetworkList)
    {
        dwNumberOfItems = (uint)Marshal.ReadInt64 (ppAvailableNetworkList);
        dwIndex = (uint)Marshal.ReadInt64 (ppAvailableNetworkList, 4);
        wlanAvailableNetwork = new WLAN_AVAILABLE_NETWORK[dwNumberOfItems];
        for (int i = 0; i < dwNumberOfItems; i++)
        {
            IntPtr pWlanAvailableNetwork = new IntPtr (ppAvailableNetworkList.ToInt64() + i * Marshal.SizeOf (typeof(WLAN_AVAILABLE_NETWORK)) + 8);
            wlanAvailableNetwork[i] = (WLAN_AVAILABLE_NETWORK)Marshal.PtrToStructure (pWlanAvailableNetwork, typeof(WLAN_AVAILABLE_NETWORK));
        }
    }
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct WLAN_AVAILABLE_NETWORK
{
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
    public string ProfileName;
    public DOT11_SSID Dot11Ssid;
    public DOT11_BSS_TYPE dot11BssType;
    public uint uNumberOfBssids;
    public bool bNetworkConnectable;
    public uint wlanNotConnectableReason;
    public uint uNumberOfPhyTypes;

    [MarshalAs(UnmanagedType.ByValArray, SizeConst = 8)]
    public DOT11_PHY_TYPE[] dot11PhyTypes;
    public bool bMorePhyTypes;
    public uint SignalQuality;
    public bool SecurityEnabled;
    public DOT11_AUTH_ALGORITHM dot11DefaultAuthAlgorithm;
    public DOT11_CIPHER_ALGORITHM dot11DefaultCipherAlgorithm;
    public uint dwFlags;
    public uint dwReserved;
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
public struct DOT11_SSID
{
    public uint uSSIDLength;

    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
    public string ucSSID;
}

public enum DOT11_BSS_TYPE
{
    Infrastructure = 1,
    Independent    = 2,
    Any            = 3,
}

public enum DOT11_PHY_TYPE
{
    dot11_phy_type_unknown = 0,
    dot11_phy_type_any = 0,
    dot11_phy_type_fhss = 1,
    dot11_phy_type_dsss = 2,
    dot11_phy_type_irbaseband = 3,
    dot11_phy_type_ofdm = 4,
    dot11_phy_type_hrdsss = 5,
    dot11_phy_type_erp = 6,
    dot11_phy_type_ht = 7,
    dot11_phy_type_vht = 8,
    dot11_phy_type_IHV_start = -2147483648,
    dot11_phy_type_IHV_end = -1,
}

public enum DOT11_AUTH_ALGORITHM
{
    DOT11_AUTH_ALGO_80211_OPEN = 1,
    DOT11_AUTH_ALGO_80211_SHARED_KEY = 2,
    DOT11_AUTH_ALGO_WPA = 3,
    DOT11_AUTH_ALGO_WPA_PSK = 4,
    DOT11_AUTH_ALGO_WPA_NONE = 5,
    DOT11_AUTH_ALGO_RSNA = 6,
    DOT11_AUTH_ALGO_RSNA_PSK = 7,
    DOT11_AUTH_ALGO_WPA3  = 8,
    DOT11_AUTH_ALGO_WPA3_SAE  = 9,
    DOT11_AUTH_ALGO_OWE  = 10,
    DOT11_AUTH_ALGO_WPA3_ENT  = 11,
    DOT11_AUTH_ALGO_IHV_START = -2147483648,
    DOT11_AUTH_ALGO_IHV_END = -1,
}

public enum DOT11_CIPHER_ALGORITHM
{
    /// DOT11_CIPHER_ALGO_NONE -> 0x00
    DOT11_CIPHER_ALGO_NONE = 0,

    /// DOT11_CIPHER_ALGO_WEP40 -> 0x01
    DOT11_CIPHER_ALGO_WEP40 = 1,

    /// DOT11_CIPHER_ALGO_TKIP -> 0x02
    DOT11_CIPHER_ALGO_TKIP = 2,

    /// DOT11_CIPHER_ALGO_CCMP -> 0x04
    DOT11_CIPHER_ALGO_CCMP = 4,

    /// DOT11_CIPHER_ALGO_WEP104 -> 0x05
    DOT11_CIPHER_ALGO_WEP104 = 5,

    /// DOT11_CIPHER_ALGO_BIP -> 0x06
    DOT11_CIPHER_ALGO_BIP = 6,

    /// DOT11_CIPHER_ALGO_GCMP -> 0x08
    DOT11_CIPHER_ALGO_GCMP = 8,

    /// DOT11_CIPHER_ALGO_GCMP_256 -> 0x09
    DOT11_CIPHER_ALGO_GCMP_256 = 9,

    /// DOT11_CIPHER_ALGO_CCMP_256 -> 0x0a
    DOT11_CIPHER_ALGO_CCMP_256 = 10,

    /// DOT11_CIPHER_ALGO_BIP_GMAC_128 -> 0x0b
    DOT11_CIPHER_ALGO_BIP_GMAC_128 = 11,

    /// DOT11_CIPHER_ALGO_BIP_GMAC_256 -> 0x0c
    DOT11_CIPHER_ALGO_BIP_GMAC_256 = 12,

    /// DOT11_CIPHER_ALGO_BIP_CMAC_256 -> 0x0d
    DOT11_CIPHER_ALGO_BIP_CMAC_256 = 13,

    /// DOT11_CIPHER_ALGO_WPA_USE_GROUP -> 0x100
    DOT11_CIPHER_ALGO_WPA_USE_GROUP = 256,

    /// DOT11_CIPHER_ALGO_RSN_USE_GROUP -> 0x100
    DOT11_CIPHER_ALGO_RSN_USE_GROUP = 256,

    /// DOT11_CIPHER_ALGO_WEP -> 0x101
    DOT11_CIPHER_ALGO_WEP = 257,

    /// DOT11_CIPHER_ALGO_IHV_START -> 0x80000000
    DOT11_CIPHER_ALGO_IHV_START = -2147483648,

    /// DOT11_CIPHER_ALGO_IHV_END -> 0xffffffff
    DOT11_CIPHER_ALGO_IHV_END = -1,
}

public enum WLAN_CONNECTION_MODE
{
    wlan_connection_mode_profile,
    wlan_connection_mode_temporary_profile,
    wlan_connection_mode_discovery_secure,
    wlan_connection_mode_discovery_unsecure,
    wlan_connection_mode_auto,
    wlan_connection_mode_invalid,
}

[Flags]
public enum WlanConnectionFlag
{
    Default                                    = 0,
    HiddenNetwork                              = 1,
    AdhocJoinOnly                              = 2,
    IgnorePrivayBit                            = 4,
    EapolPassThrough                           = 8,
    PersistDiscoveryProfile                    = 10,
    PersistDiscoveryProfileConnectionModeAuto  = 20,
    PersistDiscoveryProfileOverwriteExisting   = 40
}

[Flags]
public enum WlanProfileFlags
{
    AllUser = 0,
    GroupPolicy = 1,
    User = 2
}

public class ProfileInfo
{
    public string ProfileName;
    public string ConnectionMode;
    public string Authentication;
    public string Encryption;
    public string Password;
    public bool ConnectHiddenSSID;
    public string EAPType;
    public string ServerNames;
    public string TrustedRootCA;
    public string Xml;
}

[DllImport("Wlanapi.dll", SetLastError = true)]
public static extern uint WlanEnumInterfaces (
    [In] IntPtr hClientHandle,
    [In] IntPtr pReserved,
    [Out] out IntPtr ppInterfaceList
);

public struct WLAN_INTERFACE_INFO_LIST
{
    public uint dwNumberOfItems;
    public uint dwIndex;
    public WLAN_INTERFACE_INFO[] wlanInterfaceInfo;
    public WLAN_INTERFACE_INFO_LIST(IntPtr ppInterfaceInfoList)
    {
        dwNumberOfItems = (uint)Marshal.ReadInt32(ppInterfaceInfoList);
        dwIndex = (uint)Marshal.ReadInt32(ppInterfaceInfoList, 4);
        wlanInterfaceInfo = new WLAN_INTERFACE_INFO[dwNumberOfItems];
        IntPtr ppInterfaceInfoListTemp = new IntPtr(ppInterfaceInfoList.ToInt64() + 8);
        for (int i = 0; i < dwNumberOfItems; i++)
        {
            ppInterfaceInfoList = new IntPtr(ppInterfaceInfoListTemp.ToInt64() + i * Marshal.SizeOf(typeof(WLAN_INTERFACE_INFO)));
            wlanInterfaceInfo[i] = (WLAN_INTERFACE_INFO)Marshal.PtrToStructure(ppInterfaceInfoList, typeof(WLAN_INTERFACE_INFO));
        }
    }
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct WLAN_INTERFACE_INFO
{
    public Guid Guid;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
    public string Description;
    public WLAN_INTERFACE_STATE State;
}

public enum WLAN_INTERFACE_STATE {
    not_ready              = 0,
    connected              = 1,
    ad_hoc_network_formed  = 2,
    disconnecting          = 3,
    disconnected           = 4,
    associating            = 5,
    discovering            = 6,
    authenticating         = 7
}

[DllImport("Wlanapi.dll",SetLastError=true)]
public static extern uint WlanScan(
    IntPtr hClientHandle,
    ref Guid pInterfaceGuid,
    IntPtr pDot11Ssid,
    IntPtr pIeData,
    IntPtr pReserved
);

[DllImport("Wlanapi.dll")]
public static extern uint WlanSetInterface(
    IntPtr hClientHandle,
    ref Guid pInterfaceGuid,
    WLAN_INTF_OPCODE OpCode,
    uint dwDataSize,
    IntPtr pData ,
    IntPtr pReserved
);

public enum WLAN_INTF_OPCODE
{
    /// wlan_intf_opcode_autoconf_start -> 0x000000000
    wlan_intf_opcode_autoconf_start = 0,

    wlan_intf_opcode_autoconf_enabled,

    wlan_intf_opcode_background_scan_enabled,

    wlan_intf_opcode_media_streaming_mode,

    wlan_intf_opcode_radio_state,

    wlan_intf_opcode_bss_type,

    wlan_intf_opcode_interface_state,

    wlan_intf_opcode_current_connection,

    wlan_intf_opcode_channel_number,

    wlan_intf_opcode_supported_infrastructure_auth_cipher_pairs,

    wlan_intf_opcode_supported_adhoc_auth_cipher_pairs,

    wlan_intf_opcode_supported_country_or_region_string_list,

    wlan_intf_opcode_current_operation_mode,

    wlan_intf_opcode_supported_safe_mode,

    wlan_intf_opcode_certified_safe_mode,

    /// wlan_intf_opcode_autoconf_end -> 0x0fffffff
    wlan_intf_opcode_autoconf_end = 268435455,

    /// wlan_intf_opcode_msm_start -> 0x10000100
    wlan_intf_opcode_msm_start = 268435712,

    wlan_intf_opcode_statistics,

    wlan_intf_opcode_rssi,

    /// wlan_intf_opcode_msm_end -> 0x1fffffff
    wlan_intf_opcode_msm_end = 536870911,

    /// wlan_intf_opcode_security_start -> 0x20010000
    wlan_intf_opcode_security_start = 536936448,

    /// wlan_intf_opcode_security_end -> 0x2fffffff
    wlan_intf_opcode_security_end = 805306367,

    /// wlan_intf_opcode_ihv_start -> 0x30000000
    wlan_intf_opcode_ihv_start = 805306368,

    /// wlan_intf_opcode_ihv_end -> 0x3fffffff
    wlan_intf_opcode_ihv_end = 1073741823,
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct WlanPhyRadioState
{
    public int dwPhyIndex;
    public Dot11RadioState dot11SoftwareRadioState;
    public Dot11RadioState dot11HardwareRadioState;
}

public enum Dot11RadioState : uint
    {
        Unknown = 0,
        On,
        Off
    }
'@

Add-Type -MemberDefinition $WlanGetProfileListSig -Name ProfileManagement -Namespace WiFi -Using System.Text -PassThru

