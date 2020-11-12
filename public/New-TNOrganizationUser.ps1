function New-TNOrganizationUser {
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
        [Parameter(Mandatory)]
        [Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory)]
        [string]$Organization,
        [string]$Name,
        [string]$Email,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            if (-not $session.sc) {
                Stop-PSFFunction -Message "Only tenable.sc supported" -Continue
            }
            $org = Get-TNOrganization -Name $Organization

            if (-not $org) {
                Stop-PSFFunction -Message "Organization '$Organization' does not exist at $($session.URI)" -Continue
            }

            $params = @{
                name     = $Name
                email    = $Email
                authType = "tns"
                username = $Credential.GetNetworkCredential().UserName
                password = $Credential.GetNetworkCredential().Password
            }

            Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/organization/$($org.Id)/securityManager" -Method POST -Parameter $params | ConvertFrom-TNRestResponse
        }
    }
}