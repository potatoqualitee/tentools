function Connect-TNServer {
<#
    .SYNOPSIS
        Connects to a Nessus or tenable.sc server

    .DESCRIPTION
        Connects to a Nessus or tenable.sc server
        
    .PARAMETER ComputerName
        The network name or IP address of the Nessus or tenable.sc server
        
    .PARAMETER Port
        The port of the Nessus or tenable.sc server. Defaults to 8834 which is the default port for Nessus.
        
    .PARAMETER Credential
        The credential object (from Get-Credential) used to log into the target server. Specifies a user account that has permission to send the request. 
        
    .PARAMETER UseDefaultCredential
        Indicates that the command uses the credentials of the current user to send the web request. This can't be used with Authentication or Credential and may not be supported on all platforms.
        
    .PARAMETER AcceptSelfSignedCert
        Accept self-signed certs
        
    .PARAMETER Type
        The type of server
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> Connect-TNServer

        Connects to a Nessus or tenable.sc server
        
#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName,
        [int]$Port,
        [Management.Automation.PSCredential]$Credential,
        [switch]$UseDefaultCredential,
        [switch]$AcceptSelfSignedCert,
        [ValidateSet("tenable.sc", "Nessus")]
        [string]$Type,
        [switch]$EnableException
    )
    begin {
        if (-not $PSBoundParameters.Credential) {
            $UseDefaultCredential = $true
        }

        if ($PSVersionTable.PSEdition -eq 'Core') {
            if ($AcceptSelfSignedCert) {
                $PSDefaultParameterValues['Invoke-RestMethod:SkipCertificateCheck'] = $true
            }
        } else {
            if ($AcceptSelfSignedCert -and [System.Net.ServicePointManager]::CertificatePolicy.ToString() -ne 'IgnoreCerts') {
                $Domain = [AppDomain]::CurrentDomain
                $DynAssembly = New-Object System.Reflection.AssemblyName('IgnoreCerts')
                $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
                $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('IgnoreCerts', $false)
                $TypeBuilder = $ModuleBuilder.DefineType('IgnoreCerts', 'AutoLayout, AnsiClass, Class, Public, BeforeFieldInit', [System.Object], [System.Net.ICertificatePolicy])
                $TypeBuilder.DefineDefaultConstructor('PrivateScope, Public, HideBySig, SpecialName, RTSpecialName') | Out-Null
                $MethodInfo = [System.Net.ICertificatePolicy].GetMethod('CheckValidationResult')
                $MethodBuilder = $TypeBuilder.DefineMethod($MethodInfo.Name, 'PrivateScope, Public, Virtual, HideBySig, VtableLayoutMask', $MethodInfo.CallingConvention, $MethodInfo.ReturnType, ([Type[]] ($MethodInfo.GetParameters() | ForEach-Object { $_.ParameterType })))
                $ILGen = $MethodBuilder.GetILGenerator()
                $ILGen.Emit([Reflection.Emit.Opcodes]::Ldc_I4_1)
                $ILGen.Emit([Reflection.Emit.Opcodes]::Ret)
                $TypeBuilder.CreateType() | Out-Null

                # Disable SSL certificate validation
                [System.Net.ServicePointManager]::CertificatePolicy = New-Object IgnoreCerts
            }
        }

        # Force usage of TSL1.2 as Nessus web server only supports this and will hang otherwise
        # Source: https://stackoverflow.com/questions/32355556/powershell-invoke-restmethod-over-https
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        if (-Not $Type) {
            if ($Port -eq 443) {
                $Type = "tenable.sc"
            } else {
                $Type = "Nessus"
            }
        }

        if ($Type -and -not $Port) {
            if ($Type -eq "tenable.sc") {
                $Port = "443"
            } else {
                $Port = "8834"
            }
        }

        if ($Port -eq 443 -and $Type -eq "tenable.sc") {
            $sc = $true
        } else {
            $sc = $false
        }
    }
    process {
        foreach ($computer in $ComputerName) {
            #$null = Wait-TNServerReady -ComputerName $computer -Port $Port -SilentUntil 5 -AcceptSelfSignedCert:$AcceptSelfSignedCert
            if ($Port -eq 443) {
                $uri = "https://$($computer):$Port/rest"
                $fulluri = "$uri/token"
                if ($PSBoundParameters.Credential) {
                    $body = @{
                        username       = $Credential.UserName
                        password       = $Credential.GetNetworkCredential().password
                        releaseSession = "FALSE"
                    } | ConvertTo-Json
                } else {
                    $body = @{
                        releaseSession = "FALSE"
                    } | ConvertTo-Json
                }

                $headers = @{"HTTP" = "X-SecurityCenter" }

                $RestMethodParams = @{
                    Headers         = $headers
                    ContentType     = "application/json"
                    Method          = 'POST'
                    URI             = $fulluri
                    Body            = $body
                    ErrorVariable   = 'NessusLoginError'
                    SessionVariable = 'websession'
                }
            } else {
                $Uri = "https://$($computer):$Port"
                $fulluri = "$uri/session"
                if ($PSBoundParameters.Credential) {
                    $body = @{'username' = $Credential.UserName; 'password' = $Credential.GetNetworkCredential().password }
                } else {
                    $body = $null
                }
                $RestMethodParams = @{
                    Method          = 'Post'
                    URI             = $fulluri
                    Body            = $body
                    ErrorVariable   = 'NessusLoginError'
                    SessionVariable = 'websession'
                }
            }

            try {
                $token = Invoke-RestMethod @RestMethodParams -ErrorAction Stop
            } catch {
                $msg = Get-ErrorMessage -Record $_
                if ($msg -eq "The remote server returned an error: (401) Unauthorized") {
                    $msg = "The remote server returned an error: (401) Unauthorized. This is likely due to a bad username/password"
                }

                Stop-PSFFunction -EnableException:$EnableException -Message "$msg $_" -ErrorRecord $_ -Continue
            }

            if ($token) {
                if ($PSBoundParameters.Credential) {
                    $username = $Credential.UserName
                } else {
                    $username = "$env:USERDOMAIN\$env:USERNAME"
                }
                $usertoken = $token.token
                if (-not $usertoken) {
                    $usertoken = $token.response.token
                }

                if ($sc) {
                    $headers = @{
                        "X-SecurityCenter" = $usertoken
                    }
                } else {
                    $headers = @{
                        "X-Cookie" = "token=$usertoken"
                    }
                }
                $session = [PSCustomObject]@{
                    URI                = $uri
                    UserName           = $username
                    ComputerName       = $computer
                    Credential         = $Credential
                    Token              = $usertoken
                    Headers            = $headers
                    SessionId          = $script:NessusConn.Count
                    WebSession         = $websession
                    Sc                 = $sc
                    Bound              = $PSBoundParameters
                    ServerType         = $Type
                    ServerVersion      = $null
                    ServerVersionMajor = $null
                    MultiUser          = $null
                }
                $oldsession = $script:NessusConn | Where-Object { $PSItem.Uri -eq $uri -and $PSItem.Username }
                if ($oldsession) {
                    $null = $script:NessusConn.Remove($oldsession)
                }
                $null = $script:NessusConn.Add($session)
                $info = Get-TNServerInfo -SessionId $id
                $script:NessusConn[$($script:NessusConn.Count) - 1].MultiUser = ($info.capabilities.multi_user -eq 'full' -or $sc)
                $script:NessusConn[$($script:NessusConn.Count) - 1].ServerVersion = $info.UIVersion
                $script:NessusConn[$($script:NessusConn.Count) - 1].ServerVersionMajor = ([version]($info.UIVersion | Select-Object -First 1)).Major
                $session | Select-DefaultView -Property SessionId, UserName, URI, ServerType
            }
        }
    }
}