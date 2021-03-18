function New-TNOrganizationUser {
<#
    .SYNOPSIS
        Creates new organization users

    .DESCRIPTION
        Creates new organization users

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Credential
        The credential object (from Get-Credential) used to log into the target server. Specifies a user account that has permission to send the request.

    .PARAMETER Organization
        The name of the target organization

    .PARAMETER Name
        The name of the target organization user

    .PARAMETER Email
        The email address of the target user

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> New-TNOrganizationUser

        Creates new organization users

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory)]
        [Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory)]
        [string]$Organization,
        [string]$Name,
        [string]$Email,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
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