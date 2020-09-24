function Get-TenUser {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TenServer.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Ten
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $script:NessusConn.SessionId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TenSession -SessionId $SessionId)) {
            $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0

            $results = Invoke-TenRequest -SessionObject $session -Path '/users' -Method 'Get'
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