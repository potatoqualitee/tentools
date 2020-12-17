function Get-TNRepository {
    <#
    .SYNOPSIS
        Gets a list of repositories

    .DESCRIPTION
        Gets a list of repositories

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target repository

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNRepository -Name Acme | Remove-TNRepository

        Removes the Acme repository

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [string[]]$Name,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $params = @{
                Path            = "/repository?fields=name,description,type,dataFormat,vulnCount,remoteID,remoteIP,running,enableTrending,downloadFormat,lastSyncTime,lastVulnUpdate,createdTime,modifiedTime,organizations,correlation,nessusSchedule,ipRange,ipCount,runningNessus,lastGenerateNessusTime,running,transfer,deviceCount,typeFields"
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