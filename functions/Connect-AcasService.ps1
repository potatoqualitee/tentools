function Connect-AcasService {
    <#
    .SYNOPSIS
        Creates a connection to the Nessus website

    .DESCRIPTION
        Creates a connection to the Nessus website which persists through all commands.

    .PARAMETER ComputerName
        Target Nessus Server IP Address or FQDN

    .PARAMETER Port
        Port number of the Nessus web service. Defaults to 8834.

    .PARAMETER Credential
        Credential for connecting to the Nessus Server

    .PARAMETER UseDefaultCredential
        Use current credential for connecting to the Nessus Server

    .PARAMETER AcceptSelfSignedCert
        Use current credential for connecting to the Nessus Server

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Connect-AcasService -ComputerName acas -Credential admin
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
        [string[]]$ComputerName,
        [int]$Port = 8834,
        [Management.Automation.PSCredential]$Credential,
        [switch]$UseDefaultCredential,
        [switch]$AcceptSelfSignedCert,
        [switch]$EnableException
    )
    process {
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

        # Force usage of TSL1.2 as Nessus web server only supports this and will hang otherwise
        # Source: https://stackoverflow.com/questions/32355556/powershell-invoke-restmethod-over-https
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        foreach ($computer in $ComputerName) {
            if ($Port -eq 443) {
                $uri = "https://$($computer):$($Port)/rest"
                $fulluri = "$uri/token"
                $body = @{
                    username = $Credential.UserName
                    password = $Credential.GetNetworkCredential().password
                    releaseSession = "FALSE"
                } | ConvertTo-Json

                $headers = @{"HTTP" = "X-SecurityCenter"}

                $RestMethodParams = @{
                    Headers       = $headers
                    ContentType   = "application/json"
                    Method        = 'POST'
                    URI           = $fulluri
                    Body          = $body
                    ErrorVariable = 'NessusLoginError'
                }
            } else {
                $Uri = "https://$($computer):$($Port)"
                $fulluri = "$uri/session"
                if ($PSBoundParameters.Credential) {
                    $body = @{'username' = $Credential.UserName; 'password' = $Credential.GetNetworkCredential().password }
                }
                else {
                    $body = $null
                }
                $RestMethodParams = @{
                    Method        = 'Post'
                    URI           = $fulluri
                    Body          = $body
                    ErrorVariable = 'NessusLoginError'
                }
            }

            try {
                $token = Invoke-RestMethod @RestMethodParams -ErrorAction Stop
            }
            catch {
                $msg = Get-ErrorMessage -Record $_
                if ($msg -eq "The remote server returned an error: (401) Unauthorized") {
                    $msg = "The remote server returned an error: (401) Unauthorized. This is likely due to a bad username/password"
                }
                
                Stop-PSFFunction -Message $msg -ErrorRecord $_ -Continue
            }
            
            if ($token) {
                if ($PSBoundParameters.Credential) {
                    $username = $Credential.UserName
                }
                else {
                    $username = "$env:USERDOMAIN\$env:USERNAME"
                }
                $usertoken =  $token.token
                if (-not $usertoken) {
                    $usertoken = $token.response.token
                }
                $session = [PSCustomObject]@{
                    URI        = $uri
                    UserName   = $username
                    Credential = $Credential
                    Token      = $usertoken
                    SessionId  = $global:NessusConn.Count
                }
                [void]$global:NessusConn.Add($session)
                $session | Select-DefaultView -Property SessionId, UserName, URI
            }
        }
    }
}