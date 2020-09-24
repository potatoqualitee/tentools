function Initialize-TenServer {
    <#
    .SYNOPSIS
        Creates a new admin the Nessus website then establishes a connection using those credentials

    .DESCRIPTION
    Creates a new admin the Nessus website

    .PARAMETER ComputerName
        Target Nessus Server IP Address or FQDN

    .PARAMETER Port
        Port number of the Nessus web service. Defaults to 8834.

    .PARAMETER Credential
        Credential for connecting to the Nessus Server

    .PARAMETER UseDefaultCredential
        Use current credential for connecting to the Nessus Server

    .PARAMETER AcceptSelfSignedCert
        Accept self signed cert

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Initialize-TenServer -ComputerName acas -Credential admin
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
        [string[]]$ComputerName,
        [int]$Port,
        [Management.Automation.PSCredential]$Credential,
        [string]$Path,
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

        if (-not (Test-Path -Path $Path)) {
            Stop-PSFFunction -EnableException:$EnableException -Message "$Path not found"
            return
        }

        $license = (Get-Content -Path $Path -Raw).Replace("`r`n", "")

        foreach ($computer in $ComputerName) {
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
                #    "key":  "-----BEGIN TENABLE LICENSE-----\nd2Yya0hLZFV4bWlWWmQwWFd6Z1dhR25GRHUrdDl5d0RnM3U1NDBYTUl1Rlg1LzgyV1oweGtjUWQ0\ncVhhWXFPb2dJUUtxbjBTVTdUcnpyYnREL3RwWFVsVVRsWTk4TUtHZ3BHNkVmSGl0OURHSldCOGtH\nalNUTmRoODM4VFNNSXNOaCtiM1JKYXhmRm83d0ljbzRYR2ZJZU9DUk9BaDNyaldidytoZC9PY1Q1\nYkRlRVFkWnpQYkR1RjdKVXNMZkI0a3V2ZEplbmR0ZVpwUEVRNzduR200NFVtR2hUQUJLZDB5dEFE\nU0pGejhnaW15djZmWTZxRVBhcVM0UG4zTE5DUk5IbnlOdCtpcEtISjZDd01XS1d1a1J4MTljRm03\nR0VZQjBDc3dtM0FML3hTRDFRYSt2MDdUcHlqVkJscktrSmIvVnZIVkQxM0FZZUk1cXA3YWpLWC9Z\nWmNybnl4ZjF0MG1LVFJUMWVqQkd6RWhUUVVZQmlQNGF0Z0tvWllaQXRSellJU3M5NGU5VDBHaU8x\nYTMvc3U5d0hOcWN2REVIMGdEYjNQSG1lelVsa2ZmWlE1QTF2TXZxMGxqbVEwQW1tQ3FoMHE2dTQx\nYWNkamVkWnBKMzdUYkpHOERVMVBWRVE5WUJ0UFVXQVpYdUlqMEM5UXYvemd3NE1HQzBMd3hnb0ZQ\ncVhUN3ZEd3FJUUZ2ekhHZjIxV0JZeng1bDBDRG40TU03V3p5SWpadjhveE00aDRyQXNDV3E1TU52\nSStCVng2ZlF3U2RmOVFoK3QzSThwRUsyWXZ1dnFTcnBQMStDSFdlN1pzaVhSdEo1ZkVqTE1iT3Nw\nU2R5VEd1U3ZhekRZZzk2TmdYc01BWCszY2lUTjJYekZxYmdvbExXdGV3Rkw5NVBtUnJTWitSRjA9\nDQp7ImFjdGl2YXRpb25fY29kZSI6IkUyODItNEQwOC02NjE4LTMyODUtQ0I0NiIsInVwZGF0ZV9w\nYXNzd29yZCI6IjBiZGEwZGY2Y2ZmMDVlM2U4NTVlNGMwOWI4ZWQwOGUxIiwibmFtZSI6Ik5lc3N1\ncyBIb21lIiwidHlwZSI6ImhvbWUiLCJleHBpcmF0aW9uX2RhdGUiOjE3NTgzNzY0NzEsImlwcyI6\nMTYsInVwZGF0ZV9sb2dpbiI6IjNlNGFmNWNkZDQ3NzQ1MDg3YWYwOTViODBlNzRjYzQ2IiwiZHJt\nIjoiNmM0NmQyZjE5MGJlZGEyNjY4N2YyYTA5ODc4ZTU5ZWQifQ==\n-----END TENABLE LICENSE-----\n"
                # "{`"key`":`"-----BEGIN TENABLE LICENSE-----\nd2Yya0hLZFV4bWlWWmQwWFd6Z1dhR25GRHUrdDl5d0RnM3U1NDBYTUl1Rlg1LzgyV1oweGtjUWQ0\ncVhhWXFPb2dJUUtxbjBTVTdUcnpyYnREL3RwWFVsVVRsWTk4TUtHZ3BHNkVmSGl0OURHSldCOGtH\nalNUTmRoODM4VFNNSXNOaCtiM1JKYXhmRm83d0ljbzRYR2ZJZU9DUk9BaDNyaldidytoZC9PY1Q1\nYkRlRVFkWnpQYkR1RjdKVXNMZkI0a3V2ZEplbmR0ZVpwUEVRNzduR200NFVtR2hUQUJLZDB5dEFE\nU0pGejhnaW15djZmWTZxRVBhcVM0UG4zTE5DUk5IbnlOdCtpcEtISjZDd01XS1d1a1J4MTljRm03\nR0VZQjBDc3dtM0FML3hTRDFRYSt2MDdUcHlqVkJscktrSmIvVnZIVkQxM0FZZUk1cXA3YWpLWC9Z\nWmNybnl4ZjF0MG1LVFJUMWVqQkd6RWhUUVVZQmlQNGF0Z0tvWllaQXRSellJU3M5NGU5VDBHaU8x\nYTMvc3U5d0hOcWN2REVIMGdEYjNQSG1lelVsa2ZmWlE1QTF2TXZxMGxqbVEwQW1tQ3FoMHE2dTQx\nYWNkamVkWnBKMzdUYkpHOERVMVBWRVE5WUJ0UFVXQVpYdUlqMEM5UXYvemd3NE1HQzBMd3hnb0ZQ\ncVhUN3ZEd3FJUUZ2ekhHZjIxV0JZeng1bDBDRG40TU03V3p5SWpadjhveE00aDRyQXNDV3E1TU52\nSStCVng2ZlF3U2RmOVFoK3QzSThwRUsyWXZ1dnFTcnBQMStDSFdlN1pzaVhSdEo1ZkVqTE1iT3Nw\nU2R5VEd1U3ZhekRZZzk2TmdYc01BWCszY2lUTjJYekZxYmdvbExXdGV3Rkw5NVBtUnJTWitSRjA9\nDQp7ImFjdGl2YXRpb25fY29kZSI6IkUyODItNEQwOC02NjE4LTMyODUtQ0I0NiIsInVwZGF0ZV9w\nYXNzd29yZCI6IjBiZGEwZGY2Y2ZmMDVlM2U4NTVlNGMwOWI4ZWQwOGUxIiwibmFtZSI6Ik5lc3N1\ncyBIb21lIiwidHlwZSI6ImhvbWUiLCJleHBpcmF0aW9uX2RhdGUiOjE3NTgzNzY0NzEsImlwcyI6\nMTYsInVwZGF0ZV9sb2dpbiI6IjNlNGFmNWNkZDQ3NzQ1MDg3YWYwOTViODBlNzRjYzQ2IiwiZHJt\nIjoiNmM0NmQyZjE5MGJlZGEyNjY4N2YyYTA5ODc4ZTU5ZWQifQ==\n-----END TENABLE LICENSE-----\n`"}"

                try {
                    $null = Invoke-WebRequest @licenseparams -ErrorAction Stop
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
                $null = $PSBoundParameters.Remove("Path")
                Connect-TenService @PSBoundParameters
            } catch {
                $msg = Get-ErrorMessage -Record $_
                Stop-PSFFunction -EnableException:$EnableException -Message "$msg $_" -ErrorRecord $_ -Continue
            }
        }
    }
}