function Get-TNOrganization {
    <#
    .SYNOPSIS
        Gets an organization

    .DESCRIPTION
        Gets an organization

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
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $params = @{
                Path            = "/organization"
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