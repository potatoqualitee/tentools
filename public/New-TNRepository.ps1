function New-TNRepository {
    <#
    .SYNOPSIS
        Creates new repositories

    .DESCRIPTION
        Creates new repositories

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target repository

    .PARAMETER Description
        Description for Description

    .PARAMETER ZoneSelection
        Description for ZoneSelection

    .PARAMETER DataFormat
        Description for DataFormat

    .PARAMETER Type
        The type of repository

    .PARAMETER TrendingDays
        Description for TrendingDays

    .PARAMETER IPRange
        Description for IPRange

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> $params = @{
              Name = "Local Net"
              IPRange = "172.20.0.1/22, 192.168.0.1/28"
        }
        PS C:\> New-TNRepository @params

        Creates a new repository named Local Net with two IP ranges

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string[]]$Name,
        [string]$Description,
        [ValidateSet("auto_only", "locked", "selectable", "selectable+auto", "selectable+auto_restricted")]
        [string]$ZoneSelection = "auto_only",
        [ValidateSet("IPv4")]
        [string]$DataFormat = "IPv4",
        [ValidateSet("Local")]
        [string]$Type = "Local",
        [int]$TrendingDays = "30",
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string[]]$IpRange,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            foreach ($repositoryname in $Name) {
                $allips = $IpRange -join ", "
                $body = @{
                    name         = $repositoryname
                    description  = $Description
                    dataFormat   = $DataFormat
                    type         = $Type
                    ipRange      = $allips
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
}