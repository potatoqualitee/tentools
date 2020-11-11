function Get-TNOrganizationUser {
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
        [string[]]$Name,
        [string]$Email,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            if (-not $session.sc) {
                Stop-PSFFunction -Message "Only tenable.sc supported" -Continue
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