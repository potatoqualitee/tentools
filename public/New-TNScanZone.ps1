function New-TNScanZone {
    <#
    .SYNOPSIS
        Creates new scan zones

    .DESCRIPTION
        Creates new scan zones

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target scan zone

    .PARAMETER IPRange
        Description for IPRange

    .PARAMETER Description
        Description for Description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> New-TNScanZone

        Creates new scan zones

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string[]]$Name,
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string[]]$IpRange,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Description,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            foreach ($org in $Name) {
                $body = @{
                    name        = $org
                    ipList      = $IpRange -join ", "
                    description = $Description
                }

                $params = @{
                    SessionObject   = $session
                    Path            = "/zone"
                    Method          = "POST"
                    Parameter       = $body
                    EnableException = $EnableException
                }
                Invoke-TNRequest @params | ConvertFrom-TNRestResponse
            }
        }
    }
}