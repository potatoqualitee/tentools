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

    .EXAMPLE
    Connect-AcasService -ComputerName acas -Credential admin

    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
        [string[]]$ComputerName,
        [int]$Port = 8834,
        [Management.Automation.PSCredential]$Credential,
        [switch]$UseDefaultCredential
    )
    process {
        if ([System.Net.ServicePointManager]::CertificatePolicy.ToString() -ne 'IgnoreCerts') {
            $Domain = [AppDomain]::CurrentDomain
            $DynAssembly = New-Object System.Reflection.AssemblyName('IgnoreCerts')
            $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
            $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('IgnoreCerts', $false)
            $TypeBuilder = $ModuleBuilder.DefineType('IgnoreCerts', 'AutoLayout, AnsiClass, Class, Public, BeforeFieldInit', [System.Object], [System.Net.ICertificatePolicy])
            $TypeBuilder.DefineDefaultConstructor('PrivateScope, Public, HideBySig, SpecialName, RTSpecialName') | Out-Null
            $MethodInfo = [System.Net.ICertificatePolicy].GetMethod('CheckValidationResult')
            $MethodBuilder = $TypeBuilder.DefineMethod($MethodInfo.Name, 'PrivateScope, Public, Virtual, HideBySig, VtableLayoutMask', $MethodInfo.CallingConvention, $MethodInfo.ReturnType, ([Type[]] ($MethodInfo.GetParameters() | % {$_.ParameterType})))
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
            $Uri = "https://$($computer):$($Port)"
            $RestMethodParams = @{
                'Method'        = 'Post'
                'URI'           = "$($Uri)/session"
                'Body'          = @{'username' = $Credential.UserName; 'password' = $Credential.GetNetworkCredential().password}
                'ErrorVariable' = 'NessusLoginError'
            }

            try {
                $token = Invoke-RestMethod @RestMethodParams -ErrorAction Stop
            }
            catch {
                Stop-PSFFunction -Message "Failure" -ErrorRecord $_ -Continue
            }
            
            if ($token) {
                $session = [PSCustomObject]@{
                    URI        = $Uri
                    Credential = $Credential
                    Token      = $token.token
                    SessionId  = $Global:NessusConn.Count
                }
                [void]$Global:NessusConn.Add($session)
                $session
            }
        }
    }
}