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

    .EXAMPLE
        PS C:\> $cred = Get-Credential admin
        PS C:\> Initialize-TNServer -ComputerName nessus -Path $home\Downloads\nessus.license -Credential $cred -AcceptSelfSignedCert

        Initializes the Nessus server on localhost using the specified license and admin as the username.

        The certificate is not recognized, so AcceptSelfSignedCert is used to bypass the restriction

#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        [int]$Port,
        [Parameter(Mandatory)]
        [Management.Automation.PSCredential]$Credential,
        [string]$LicensePath,
        [switch]$AcceptSelfSignedCert,
        [ValidateSet("tenable.sc", "Nessus")]
        [string[]]$Type = @("tenable.sc", "Nessus"),
        [switch]$ManagedScanner,
        [switch]$EnableException
    )
    begin {
        if ($PSVersionTable.PSEdition -eq "Core") {
            if ($AcceptSelfSignedCert) {
                $PSDefaultParameterValues["Invoke-RestMethod:SkipCertificateCheck"] = $true
            }
        } else {
            if ($AcceptSelfSignedCert -and [System.Net.ServicePointManager]::CertificatePolicy.ToString() -ne "IgnoreCerts") {
                $Domain = [AppDomain]::CurrentDomain
                $DynAssembly = New-Object System.Reflection.AssemblyName("IgnoreCerts")
                $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
                $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule("IgnoreCerts", $false)
                $TypeBuilder = $ModuleBuilder.DefineType("IgnoreCerts", "AutoLayout, AnsiClass, Class, Public, BeforeFieldInit", [System.Object], [System.Net.ICertificatePolicy])
                $TypeBuilder.DefineDefaultConstructor("PrivateScope, Public, HideBySig, SpecialName, RTSpecialName") | Out-Null
                $MethodInfo = [System.Net.ICertificatePolicy].GetMethod("CheckValidationResult")
                $MethodBuilder = $TypeBuilder.DefineMethod($MethodInfo.Name, "PrivateScope, Public, Virtual, HideBySig, VtableLayoutMask", $MethodInfo.CallingConvention, $MethodInfo.ReturnType, ([Type[]] ($MethodInfo.GetParameters() | ForEach-Object { $_.ParameterType })))
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
    }
    process {
        if (-not $ManagedScanner -and -not $LicensePath) {
            Stop-PSFFunction -EnableException:$EnableException -Message "You must specify either ManagedScanner or LicensePath"
            return
        }

        if ($Type -contains "tenable.sc" -and -not $LicensePath) {
            Stop-PSFFunction -EnableException:$EnableException -Message "You must specify either LicensePath when initializing tenable.sc"
            return
        }

        if ($LicensePath -and -not (Test-Path -Path $LicensePath)) {
            Stop-PSFFunction -EnableException:$EnableException -Message "$LicensePath not found"
            return
        }

        if ($LicensePath) {
            $license = (Get-Content -Path $LicensePath -Raw).Replace("`r`n", "")
        }

        $lp = $LicensePath
        $servertypes = $Type
        $managed = $ManagedScanner
        $null = $PSBoundParameters.Remove("LicensePath")
        $null = $PSBoundParameters.Remove("Type")
        $null = $PSBoundParameters.Remove("ManagedScanner")


        foreach ($computer in $ComputerName) {
            Write-PSFMessage -Level Verbose -Message "Connecting to $computer"
            Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Connecting to $computer"

            # CREATE OUTPUT OBJECT
            $output = @{
                Computer     = $computer
                AdminAccount = $Credential.UserName
                Connected    = $false
                LicensePath  = $LicensePath
                Session      = $null
                Success      = $false
                Type         = $null
            }

            # ADD TYPE STUFF HERE THEN SAY IF BOTH THEN DONT USE THE LICENSE

            foreach ($servertype in $servertypes) {
                if (-not $PSBoundParameters.Port) {
                    if ($servertype -eq "tenable.sc") {
                        $Port = "443"
                    } else {
                        $Port = "8834"
                    }
                }
                if ($servertype -eq "tenable.sc") {
                    <#
                    #
                    #
                    #                            tenable.sc
                    #
                    #
                    #>
                    $output.Type = "tenable.sc"
                    try {
                        $session = Connect-TNServer -ComputerName $computer -InitialConnect -Type $servertype -Credential $Credential -EnableException
                    } catch {
                        $msg = Get-ErrorMessage -Record $_
                        Stop-PSFFunction -EnableException:$EnableException -Message "$msg $_" -ErrorRecord $_ -Continue
                    }

                    $files = Get-ChildItem -Path $lp
                    foreach ($file in $files.FullName) {
                        $body = $file | Publish-File -Session $session -ErrorAction Stop -Type Report

                        $params = @{
                            SessionObject   = $session
                            Method          = "POST"
                            Path            = "/config/license/register"
                            Parameter       = $body
                            ContentType     = "application/json"
                            EnableException = $true
                        }

                        Write-PSFMessage -Level Verbose -Message "Uploading license to $computer"
                        Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Uploading license to $computer"
                        try {
                            $null = Invoke-TnRequest @params | ConvertFrom-TNRestResponse
                        } catch {
                            $msg = Get-ErrorMessage -Record $_
                            Stop-PSFFunction -EnableException:$EnableException -Message "$msg $_" -ErrorRecord $_ -Continue
                        }
                    }

                    # add or modify username
                    if ($Credential.UserName -ne "admin") {
                        $body = @{
                            username    = $Credential.UserName
                            password    = $Credential.GetNetworkCredential().Password
                            permissions = "128"
                            authType    = "tns"
                            roleID      = 1
                        } | ConvertTo-Json

                        $params = @{
                            Path            = "/user"
                            Method          = "POST"
                            ContentType     = "application/json"
                            Parameter       = $body
                            EnableException = $true
                        }
                        Write-PSFMessage -Level Verbose -Message "Creating admin account on $computer"
                        Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating admin account on $computer"
                        try {
                            $null = Invoke-TnRequest @params
                        } catch {
                            $msg = Get-ErrorMessage -Record $_
                            Stop-PSFFunction -EnableException:$EnableException -Message "$msg $_" -ErrorRecord $_ -Continue
                        }
                    } else {
                        $body = @{
                            password = $Credential.GetNetworkCredential().Password
                        } | ConvertTo-Json

                        $params = @{
                            Path            = "/user/1"
                            Method          = "PATCH"
                            ContentType     = "application/json"
                            Parameter       = $body
                            EnableException = $true
                        }
                        Write-PSFMessage -Level Verbose -Message "Modifying admin account password"
                        Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Modifying admin account password"
                        try {
                            $null = Invoke-TnRequest @params
                        } catch {
                            $msg = Get-ErrorMessage -Record $_
                            Stop-PSFFunction -EnableException:$EnableException -Message "$msg $_" -ErrorRecord $_ -Continue
                        }
                    }

                    Write-PSFMessage -Level Verbose -Message "Connecting to $computer with new admin credentials for tenable.sc"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Connecting to $computer with new admin credentials for tenable.sc"
                    try {
                        $session = Connect-TNServer @PSBoundParameters -Type $servertype
                        $output.Connected = $true
                        $output.Session = $session
                    } catch {
                        $msg = Get-ErrorMessage -Record $_
                        Stop-PSFFunction -EnableException:$EnableException -Message "$msg $_" -ErrorRecord $_ -Continue
                    }
                } else {
                    <#
                    #
                    #
                    #                            Nessus
                    #
                    #
                    #>

                    $output.Type = "Nessus"
                    $null = Wait-TNServerReady -ComputerName $computer -Port $Port -Register -WarningAction SilentlyContinue -AcceptSelfSignedCert:$AcceptSelfSignedCert
                    $Uri = "https://$($computer):$Port"


                    $fulluri = "$uri/users"
                    $body = @{
                        username    = $Credential.UserName
                        password    = $Credential.GetNetworkCredential().password
                        permissions = "128"
                    } | ConvertTo-Json

                    $adminuserparams = @{
                        Method          = "POST"
                        ContentType     = "application/json"
                        URI             = $fulluri
                        Body            = $body
                        ErrorVariable   = "NessusLoginError"
                        SessionVariable = "websession"
                        ErrorAction     = "Stop"
                    }

                    Write-PSFMessage -Level Verbose -Message "Creating new admin account for Nessus on $computer"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating new admin account for Nessus on $computer"
                    try {
                        $null = Invoke-RestMethod @adminuserparams
                    } catch {
                        $details = ($_.ErrorDetails | ConvertFrom-Json).error
                        Stop-PSFFunction -EnableException:$EnableException -Message "Nessus reports: $details" -Continue
                    }

                    ################ RESTART

                    $fulluri = "$uri/server/restart"

                    $restartparams = @{
                        Method        = "POST"
                        ContentType   = "application/json"
                        URI           = $fulluri
                        ErrorVariable = "NessusLoginError"
                        WebSession    = $websession
                        ErrorAction   = "Stop"
                    }

                    Write-PSFMessage -Level Verbose -Message "Restarting Nessus on $computer"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Restarting Nessus on $computer"
                    try {
                        $null = Invoke-RestMethod @restartparams
                    } catch {
                        $details = ($_.ErrorDetails | ConvertFrom-Json).error
                        Stop-PSFFunction -EnableException:$EnableException -Message "Nessus reports: $details" -Continue
                    }

                    ################ REGISTER

                    if ($Type -notcontains "tenable.sc" -and -not $managed) {
                        $fulluri = "$uri/server/register"

                        $body = @{
                            "key" = $license
                        } | ConvertTo-Json

                        $licenseparams = @{
                            Method        = "POST"
                            ContentType   = "application/json"
                            URI           = $fulluri
                            Body          = $body
                            ErrorVariable = "NessusLicenseError"
                            ErrorAction   = "Stop"
                        }

                        Write-PSFMessage -Level Verbose -Message "Uploading license for Nessus on $computer"
                        Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Uploading license for Nessus on $computer"
                        try {
                            $null = Invoke-RestMethod @licenseparams
                        } catch {
                            $details = ($_.ErrorDetails | ConvertFrom-Json).error
                            Stop-PSFFunction -EnableException:$EnableException -Message "Nessus reports: $details" -Continue
                        }
                    }

                    if (-not $managed) {
                        Write-PSFMessage -Level Verbose -Message "Connecting to Nessus on $computer"
                        Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Connecting to Nessus on $computer"
                        try {
                            $session = Connect-TNServer @PSBoundParameters -NoWait
                            $output.Connected = $true
                            $output.Session = $session
                        } catch {
                            $msg = Get-ErrorMessage -Record $_
                            Stop-PSFFunction -EnableException:$EnableException -Message "$msg $_" -ErrorRecord $_ -Continue
                        }
                    }
                }
                $output.Success = $true
                [pscustomobject]$output | ConvertFrom-TNRestResponse
            }
        }
    }
}