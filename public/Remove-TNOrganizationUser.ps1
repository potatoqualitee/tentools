function Remove-TNOrganizationUser {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER Credential
    Credential for connecting to the Nessus Server

    .PARAMETER Permission
        Parameter description

    .PARAMETER Type
        Parameter description

    .PARAMETER Email
        Parameter description

    .PARAMETER Name
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TN
    #>
    [CmdletBinding()]
    param
    (
        [string[]]$Organization,
        [Alias("Username")]
        [string]$Name,
        [parameter(ValueFromPipeline)]
        [object[]]$InputObject,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            if (-not $session.sc) {
                Stop-PSFFunction -Message "Only tenable.sc supported" -Continue
            }

            if (-not $InputObject) {
                $InputObject = Get-TNOrganizationUser -Organization $Organization -Name $Name
                if (-not $InputObject) {
                    Stop-PSFFunction -Message "User $Name does not in exist at $($session.URI)" -Continue
                }
            }

            foreach ($user in $InputObject) {
                $params = @{
                    SessionObject   = $session
                    EnableException = $EnableException
                    Method          = "DELETE"
                    Path            = "/organization/$($user.OrganizationId)/securityManager/$($user.Id)"
                }
                Invoke-TNRequest @params | ConvertFrom-TNRestResponse
            }
        }
    }
}