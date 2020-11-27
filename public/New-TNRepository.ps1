function New-TNRepository {
    <#
    .SYNOPSIS
        Adds a repository

    .DESCRIPTION
        Adds a repository

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
        [ValidateSet("auto_only", "locked", "selectable", "selectable+auto", "selectable+auto_restricted")]
        [string]$ZoneSelection = "auto_only",
        [ValidateSet("IPv4")]
        [string]$DataFormat = "IPv4",
        [ValidateSet("Local")]
        [string]$Type = "Local",
        [int]$TrendingDays = "30",
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$IPRange,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $body = @{
                name         = $Name
                description  = $Description
                dataFormat   = $DataFormat
                type         = $Type
                ipRange      = $IpRange
                trendingDays = $TrendingDays
                trendWithRaw = "true"
            }

            $params = @{
                SessionObject   = $session
                Path            = "/repository"
                Method          = "POST"
                Parameter       = $body
                EnableException = $EnableException
            }
            Invoke-TNRequest @params | ConvertFrom-TNRestResponse
        }
    }
}