function New-TNOrganization {
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
        PS>  New-TNOrganization -Name "Acme Corp"

    #>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string[]]$Name,
        [ValidateSet("auto_only", "locked", "selectable", "selectable+auto", "selectable+auto_restricted")]
        [string]$ZoneSelection = "auto_only",
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            if (-not $session.sc) {
                Stop-PSFFunction -Message "Only tenable.sc supported" -Continue
            }

            foreach ($org in $Name) {
                $body = @{
                    name          = $org
                    zoneSelection = $ZoneSelection
                    ipInfoLinks   = (@{name = "SANS"; link = "https://isc.sans.edu/ipinfo.html?ip=%IP%" }, @{name = "ARIN"; link = "http://whois.arin.net/rest/ip/%IP%" })
                }

                $params = @{
                    Path            = "/organization"
                    Method          = "POST"
                    Parameter       = $body
                    EnableException = $EnableException
                }
                Invoke-TNRequest @params | ConvertFrom-TNRestResponse
            }
        }
    }
}