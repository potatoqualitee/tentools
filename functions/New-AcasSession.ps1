function New-AcasSession {
    <#
    .SYNOPSIS

    .DESCRIPTION
    Long description

    .PARAMETER ComputerName
    Nessus Server IP Address or FQDN to connect to.

    .PARAMETER Port
    Port number of the Nessus web service. Default 8834

    .PARAMETER Credential
    Credentials for connecting to the Nessus Server

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
        [string[]]$ComputerName,
        [int]$Port = 8834,
        [Parameter(Mandatory,Position = 1)]
        [Management.Automation.PSCredential]$Credential
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

        $SessionProps = New-Object -TypeName System.Collections.Specialized.OrderedDictionary

        foreach ($computer in $ComputerName) {
            $URI = "https://$($computer):$($Port)"
            $RestMethodParams = @{
                'Method'        = 'Post'
                'URI'           = "$($URI)/session"
                'Body'          = @{'username' = $Credential.UserName; 'password' = $Credential.GetNetworkCredential().password}
                'ErrorVariable' = 'NessusLoginError'
            }

            $TokenResponse = Invoke-RestMethod @RestMethodParams
            if ($TokenResponse) {
                $SessionProps.add('URI', $URI)
                $SessionProps.Add('Credentials', $Credential)
                $SessionProps.add('Token', $TokenResponse.token)
                $SessionIndex = $Global:NessusConn.Count
                $SessionProps.Add('SessionId', $SessionIndex)
                $sessionobj = New-Object -TypeName psobject -Property $SessionProps
                $sessionobj.pstypenames[0] = 'Nessus.Session'

                [void]$Global:NessusConn.Add($sessionobj)

                $sessionobj
            }
        }
    }
}