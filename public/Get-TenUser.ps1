function Get-TNUser {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

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
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {

            if (-not $session.sc -and $session.ServerVersionMajor -ge 8) {
                Stop-PSFFunction -Message "Nessus 8 and above not supported :("
                return
            }

            $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0

            $results = Invoke-TNRequest -SessionObject $session -Path '/users' -Method GET
            if ($session.sc) {
                foreach ($user in $results) {
                    [pscustomobject]@{
                        UserName           = $user.username
                        FirstName          = $user.firstname
                        LastName           = $user.lastname
                        Title              = $user.title
                        Email              = $user.email
                        Address            = $user.address
                        City               = $user.city
                        State              = $user.state
                        Country            = $user.country
                        UserId             = $user.id
                        Status             = $user.status
                        Fax                = $user.fax
                        Type               = $user.type
                        LastLogin          = $origin.AddSeconds($user.lastlogin).ToLocalTime()
                        LastLoginIp        = $user.lastLoginIP
                        CreatedTime        = $origin.AddSeconds($user.createdTime).ToLocalTime()
                        ModifiedTime       = $origin.AddSeconds($user.modifiedTime).ToLocalTime()
                        MustChangePassword = $user.mustChangePassword
                        Locked             = $user.locked
                        AuthType           = $user.authType
                        Fingerprint        = $user.fingerprint
                        Password           = $user.password
                        LdapUserName       = $user.ldapUsername
                        CanUse             = $user.canUse
                        CanManage          = $user.canManage
                        ApiKeys            = $user.apiKeys
                        Ldap               = $user.ldap
                        Role               = $user.role
                        Preferences        = $user.preferences
                    }
                }
            } else {
                foreach ($user in $results.users) {
                    [pscustomobject]@{
                        Name       = $user.name
                        UserName   = $user.username
                        Email      = $user.email
                        UserId     = $user.id
                        Type       = $user.type
                        Permission = $permidenum[$user.permissions]
                        LastLogin  = $origin.AddSeconds($user.lastlogin).ToLocalTime()
                    }
                }
            }
        }
    }
}