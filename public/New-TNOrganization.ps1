function New-TNOrganization {
    <#
    .SYNOPSIS
        Creates new organizations

    .DESCRIPTION
        Creates new organizations

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target organization

    .PARAMETER ZoneSelection
        Description for ZoneSelection

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> New-TNOrganization -Name "Acme Corp"

        Creates a new organization named Acme Corp

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string[]]$Name,
        [ValidateSet("auto_only", "locked", "selectable", "selectable+auto", "selectable+auto_restricted")]
        [string]$ZoneSelection = "auto_only",
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
                    name          = $org
                    zoneSelection = $ZoneSelection
                    ipInfoLinks   = (@{name = "SANS"; link = "https://isc.sans.edu/ipinfo.html?ip=%IP%" }, @{name = "ARIN"; link = "http://whois.arin.net/rest/ip/%IP%" })
                }

                $params = @{
                    SessionObject   = $session
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