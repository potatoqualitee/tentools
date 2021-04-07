function Add-TNScanner {
    <#
    .SYNOPSIS
        Adds new Nessus scanners to tenable.sc

    .DESCRIPTION
        Adds new Nessus scanners to tenable.sc

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target Nessus scanner

    .PARAMETER IPRange
        Description for IPRange

    .PARAMETER Description
        Description for Description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Add-TNScanner

        Adds new Nessus scanners

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string[]]$ComputerName,
        [int]$Port = 8834,
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [pscredential]$Credential,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Description,
        [ValidateSet("password")]
        [string]$AuthenticationType = "password",
        [switch]$VerifyHost,
        [switch]$EnableException
    )
    process {
        if ($PSBoundParameters.ComputerName.Count -gt 1 -and $PSBoundParameters.Name) {
            Stop-PSFFunction -EnableException:$EnableException -Message "You cannot specify Name when targeting multiple ComputerNames"
            return
        }

        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            foreach ($computer in $ComputerName) {
                if (-not $PSBoundParameters.Name) {
                    $scannername = $computer
                } else {
                    $scannername = $Name | Select-Object -First 1
                }
                $body = @{
                    name         = $scannername
                    ip           = $computer
                    description  = $Description
                    authType     = $AuthenticationType
                    username     = $Credential.UserName
                    password     = $Credential.GetNetworkCredential().Password
                    port         = $Port
                    verifyHost   = $VerifyHost.ToString().ToLower()
                    useProxy     = $false.ToString().ToLower()
                    enable       = $true.ToString().ToLower()
                    agentCapable = $false.ToString().ToLower()
                }

                $params = @{
                    SessionObject   = $session
                    Path            = "/scanner"
                    Method          = "POST"
                    Parameter       = $body
                    EnableException = $EnableException
                }
                Invoke-TNRequest @params | ConvertFrom-TNRestResponse
            }
        }
    }
}