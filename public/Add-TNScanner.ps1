function Add-TNScanner {
    <#
    .SYNOPSIS
        Adds a list of scanners

    .DESCRIPTION
        Adds a list of scanners

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target scanner

    .PARAMETER Description
        Description for Description

    .PARAMETER ComputerName
        The network name or IP address of the Nessus or tenable.sc server

    .PARAMETER Credential
        The credential object (from Get-Credential) used to log into the target server. Specifies a user account that has permission to send the request.

    .PARAMETER Port
        The port of the Nessus or tenable.sc server. Defaults to 8834 which is the default port for Nessus.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Add-TNScanner -Name CNScanner -ComputerName cnscanner1 -Credential admin

        Adds the Nessus scanner, cnscanner1, with the name "CNScanner" using the Nessus credential "admin"

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$Name,
        [string]$Description,
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string[]]$ComputerName,
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [pscredential]$Credential,
        [int]$Port = 8834,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            foreach ($computer in $ComputerName) {
                $body = @{
                    name        = $Name
                    description = $Description
                    authType    = "password"
                    username    = $Credential.UserName
                    password    = $Credential.GetNetworkCredential().Password
                    ip          = $computer
                    port        = $Port
                    enabled     = "true"
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