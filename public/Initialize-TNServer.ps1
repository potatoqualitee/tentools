function Initialize-TNServer {
    <#
    .SYNOPSIS
        Initializes a list of servers

    .DESCRIPTION
        Initializes a list of servers

    .PARAMETER ComputerName
        The network name or IP address of the Nessus or tenable.sc server

    .PARAMETER Port
        The port of the Nessus or tenable.sc server. Defaults to 8834 which is the default port for Nessus.

    .PARAMETER Credential
        The credential object (from Get-Credential) used to log into the target server. Specifies a user account that has permission to send the request.

    .PARAMETER LicensePath
        Description for LicensePath

    .PARAMETER AcceptSelfSignedCert
        Accept self-signed certs

    .PARAMETER Type
        The type of server - nessus or tenable.sc

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Initialize-TNServer -ComputerName localhost -Path $home\Downloads\nessus.license -Credential admin

        Initializes the Nessus server on localhost using the specified license and admin as the username

#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        [int]$Port,
        [Parameter(Mandatory)]
        [Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory)]
        [string]$LicensePath,
        [switch]$AcceptSelfSignedCert,
        [ValidateSet("tenable.sc", "Nessus")]
        [string]$Type,
        [switch]$EnableException
    )
    begin {
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
    }
    process {
        if (-not (Test-Path -Path $LicensePath)) {
            Stop-PSFFunction -EnableException:$EnableException -Message "$LicensePath not found"
            return
        }

        $license = (Get-Content -Path $LicensePath -Raw).Replace("`r`n", "")

        foreach ($computer in $ComputerName) {
            $null = Wait-TNServerReady -ComputerName $computer -Port $Port -Register -WarningAction SilentlyContinue -AcceptSelfSignedCert:$AcceptSelfSignedCert
            if ($Port -eq 443) {
                $uri = "https://$($computer):$Port/rest"
                $fulluri = "$uri/user"
                $body = @{
                    username    = $Credential.UserName
                    password    = $Credential.GetNetworkCredential().password
                    permissions = "128"
                } | ConvertTo-Json

                $headers = @{"HTTP" = "X-SecurityCenter" }

                try {
                    $null = Invoke-RestMethod @adminuserparams -ErrorAction Stop
                } catch {
                    $msg = Get-ErrorMessage -Record $_
                    Stop-PSFFunction -EnableException:$EnableException -Message "$msg $_" -ErrorRecord $_ -Continue
                }

                $adminuserparams = @{
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
                $fulluri = "$uri/server/register"

                $body = @{
                    "key" = $license
                } | ConvertTo-Json

                $licenseparams = @{
                    Method        = 'POST'
                    ContentType   = "application/json"
                    URI           = $fulluri
                    Body          = $body
                    ErrorVariable = 'NessusLicenseError'
                }

                try {
                    $null = Invoke-RestMethod @licenseparams -ErrorAction Stop
                } catch {
                    $msg = Get-ErrorMessage -Record $_
                    Stop-PSFFunction -EnableException:$EnableException -Message "$msg $_" -ErrorRecord $_ -Continue
                }

                $fulluri = "$uri/users"
                $body = @{
                    username    = $Credential.UserName
                    password    = $Credential.GetNetworkCredential().password
                    permissions = "128"
                } | ConvertTo-Json

                $adminuserparams = @{
                    Method          = 'POST'
                    ContentType     = "application/json"
                    URI             = $fulluri
                    Body            = $body
                    ErrorVariable   = 'NessusLoginError'
                    SessionVariable = 'websession'
                }
            }


            try {
                $null = Invoke-RestMethod @adminuserparams -ErrorAction Stop
                $null = $PSBoundParameters.Remove("LicensePath")
                Connect-TNServer @PSBoundParameters
                Restart-TNService
            } catch {
                $msg = Get-ErrorMessage -Record $_
                Stop-PSFFunction -EnableException:$EnableException -Message "$msg $_" -ErrorRecord $_ -Continue
            }
        }
    }
}