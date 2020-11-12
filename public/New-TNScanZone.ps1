function New-TNScanZone {
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
        PS>  New-TNScanZone -Name "Acme Corp"

    #>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string[]]$Name,
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string[]]$IPRange,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Description,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            if (-not $session.sc) {
                Stop-PSFFunction -Message "Only tenable.sc supported" -Continue
            }

            foreach ($org in $Name) {
                $body = @{
                    name        = $org
                    ipList      = $IPRange -join ", "
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