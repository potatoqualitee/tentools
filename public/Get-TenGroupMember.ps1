function Get-TenGroupMember {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TenService.

    .PARAMETER GroupId
        Parameter description

    .EXAMPLE
        PS> Get-Ten

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $script:NessusConn.SessionId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1)]
        [int32]$GroupId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TenSession -SessionId $SessionId)) {
            $serverparams = @{
                SessionObject = $session
                Path          = '/server/properties'
                Method        = 'GET'
            }

            $server = Invoke-TenRequest @serverparams

            if ($server.capabilities.multi_user -eq 'full' -or $session.sc) {
                $groupparams = @{
                    SessionObject = $session
                    Path          = "/groups/$GroupId/users"
                    Method        = 'GET'
                }

                $results = (Invoke-TenRequest @groupparams).users
                if ($Session.sc) {
                    [pscustomobject]@{
                        UserName  = $user.username
                        FirstName = $user.firstname
                        LastName  = $user.lastname
                        UserId    = $_Userid
                        SessionId = $session.SessionId
                    }
                } else {
                    $users = $results.users
                    foreach ($user in $users) {
                        [pscustomobject]@{
                            Name       = $user.name
                            UserName   = $user.username
                            Email      = $user.email
                            UserId     = $_Userid
                            Type       = $user.type
                            Permission = $permidenum[$user.permissions]
                            LastLogin  = $origin.AddSeconds($user.lastlogin).ToLocalTime()
                            SessionId  = $session.SessionId
                        }
                    }
                }
            } else {
                Write-PSFMessage -Level Warning -Message "Server ($($session.ComputerName)) for session $($session.sessionid) is not licenced for multiple users"
            }
        }
    }
}