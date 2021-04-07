function New-TNUser {
<#
    .SYNOPSIS
        Creates new users

    .DESCRIPTION
        Creates new users

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Credential
        The credential object (from Get-Credential) used to log into the target server. Specifies a user account that has permission to send the request.

    .PARAMETER Permission
        Description for Permission

    .PARAMETER Type
        The type of user

    .PARAMETER Email
        The email address of the target user

    .PARAMETER Name
        The name of the target user

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> New-TNUser

        Creates new users

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory)]
        [Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory)]
        [ValidateSet('Read-Only', 'Regular', 'Administrator', 'Sysadmin')]
        [string]$Permission,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('Local', 'LDAP')]
        [string]$Type = 'Local',
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Email,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Name,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            $params = @{ }
            $params.Add('type', $Type.ToLower())
            $params.Add('permissions', $permenum[$Permission])
            $params.Add('username', $Credential.GetNetworkCredential().UserName)
            $params.Add('password', $Credential.GetNetworkCredential().Password)

            if ($Email.Length -gt 0) {
                $params.Add('email', $Email)
            }

            if ($Name.Length -gt 0) {
                $params.Add('name', $Name)
            }

            Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path '/users' -Method 'Post' -Parameter $params
        }
    }
}