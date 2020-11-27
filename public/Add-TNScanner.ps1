function Add-TNScanner {
    <#
    .SYNOPSIS
        Adds a scanner

    .DESCRIPTION
        Adds a scanner

    .PARAMETER Name
        Parameter description

    .PARAMETER ZoneSelection
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS>  $params = @{
              Name = "Local Net"
              IPRange = "172.20.0.1/22, 192.168.0.1/28"
        }
        PS>  New-TNRepository @params

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