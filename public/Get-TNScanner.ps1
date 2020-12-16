function Get-TNScanner {
    <#
    .SYNOPSIS
        Gets a list of scanners

    .DESCRIPTION
        Gets a list of scanners

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target scanner

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNScanner

        Gets a list of scanners

    .EXAMPLE
        PS C:\> Get-TNScanner -Name scanner1, scanner2

        Gets information for scanners with name scanner1 and scanner2

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $params = @{
                Path            = "/scanner?fields=authType,admin,state,useProxy,verifyHost,enabled,cert,certInfo,username,password,description,createdTime,loadedPluginSet,pluginSet,webVersion,version,zones,agentCapable,accessKey,secretKey,nessusManagerOrgs,msp,loadAvg,numHosts,numScans,numSessions,numTCPSessions,serverUUID,name,ip,port,version,type,status,uptime,modifiedTime,msp,admin,agentCapable,SCI,pluginSet"
                Method          = "GET"
                EnableException = $EnableException
            }

            if ($PSBoundParameters.Name) {
                Invoke-TNRequest @params | ConvertFrom-TNRestResponse -ExcludeEmptyResult | Where-Object Name -in $Name
            } else {
                Invoke-TNRequest @params | ConvertFrom-TNRestResponse -ExcludeEmptyResult
            }
        }
    }
}