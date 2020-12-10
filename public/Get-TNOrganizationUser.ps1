function Get-TNOrganizationUser {
    <#
    .SYNOPSIS
        Gets a list of organization users

    .DESCRIPTION
        Gets a list of organization users

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

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
        PS C:\> Get-TNOrganizationUser

        Gets a list of all organization users

    .EXAMPLE
        PS C:\> Get-TNOrganizationUser -Organization CNN

        Gets a list of organization users for the CNN organization

    .EXAMPLE
        PS C:\> Get-TNOrganizationUser -Organization CNN -Name pbuffet

        Gets the organization user named pbuffet for the CNN organization

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [string[]]$Organization,
        [string[]]$Name,
        [string]$Email,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }
            $orgs = Get-TNOrganization -Name $Organization

            if (-not $orgs) {
                Stop-PSFFunction -Message "Organization '$Organization' does not exist at $($session.URI)" -Continue
            }

            foreach ($org in $orgs) {
                $users = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/organization/$($org.Id)/user" -Method GET
                foreach ($user in $users) {
                    $results = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/organization/$($org.Id)/user/$($user.id)?fields=id,firstname,lastname,status,role,username,title,email,address,city,state,country,phone,fax,createdTime,modifiedTime,lastLogin,lastLoginIP,mustChangePassword,locked,failedLogins,authType,fingerprint,password,description,responsibleAsset,group,managedUsersGroups,managedObjectsGroups,orgName,canUse,canManage,preferences,ldap,ldapUsername,parent" -Method GET
                    $null = $results | Add-Member -MemberType NoteProperty -Name OrganizationId -Value $org.Id
                    $null = $results | Add-Member -MemberType NoteProperty -Name Organization -Value $org.Name

                    if ($PSBoundParameters.Name) {
                        $results | ConvertFrom-TNRestResponse | Where-Object Name -in $Name
                    } else {
                        $results | ConvertFrom-TNRestResponse | Where-Object ErrorCode -ne 0
                    }
                }
            }
        }
    }
}