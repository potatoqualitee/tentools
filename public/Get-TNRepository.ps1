function Get-TNRepository {
    <#
    .SYNOPSIS
        Adds an organization

    .DESCRIPTION
        Adds an organization

    .PARAMETER Name
        Parameter description

    .PARAMETER ZoneSelection
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS>  Get-TNRepository

    #>
    [CmdletBinding()]
    param
    (
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            if (-not $session.sc) {
                Stop-PSFFunction -Message "Only tenable.sc supported" -Continue
            }

            $params = @{
                Path            = "/repository?fields=name,description,type,dataFormat,vulnCount,remoteID,remoteIP,running,enableTrending,downloadFormat,lastSyncTime,lastVulnUpdate,createdTime,modifiedTime,organizations,correlation,nessusSchedule,ipRange,ipCount,runningNessus,lastGenerateNessusTime,running,transfer,deviceCount,typeFields"
                Method          = "GET"
                EnableException = $EnableException
            }
            Invoke-TNRequest @params | ConvertFrom-TNRestResponse
        }
    }
}