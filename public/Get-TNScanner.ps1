function Get-TNScanner {
    <#
    .SYNOPSIS
        Gets a scanner

    .DESCRIPTION
        Gets a scanner

    .PARAMETER Name
        Parameter description

    .PARAMETER ZoneSelection
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS>  New-TNOrganization -Name "Acme Corp"

    #>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            if (-not $session.sc) {
                Stop-PSFFunction -Message "Only tenable.sc supported" -Continue
            }

            $params = @{
                Path            = "/scanner?fields=authType,admin,state,useProxy,verifyHost,enabled,cert,certInfo,username,password,description,createdTime,loadedPluginSet,pluginSet,webVersion,version,zones,agentCapable,accessKey,secretKey,nessusManagerOrgs,msp,loadAvg,numHosts,numScans,numSessions,numTCPSessions,serverUUID,name,ip,port,version,type,status,uptime,modifiedTime,msp,admin,agentCapable,SCI,pluginSet"
                Method          = "GET"
                EnableException = $EnableException
            }

            if ($PSBoundParameters.Name) {
                Invoke-TNRequest @params | ConvertFrom-TNRestResponse | Where-Object Name -in $Name
            } else {
                Invoke-TNRequest @params | ConvertFrom-TNRestResponse
            }
        }
    }
}