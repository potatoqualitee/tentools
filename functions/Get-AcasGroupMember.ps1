function Get-AcasGroupMember {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER GroupId
        Parameter description

    .EXAMPLE
        PS> Get-Acas

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1)]
        [int32]$GroupId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            
            $serverTypeParams = @{
                SessionObject = $session
                Path          = '/server/properties'
                Method        = 'GET'
            }

            $server = Invoke-AcasRequest @ServerTypeParams

            if ($server.capabilities.multi_user -eq 'full') {
                $GroupParams = @{
                    SessionObject = $session
                    Path          = "/groups/$($GroupId)/users"
                    Method        = 'GET '
                }

                foreach ($User in (Invoke-AcasRequest @GroupParams).users) {
                    [pscustomobject]@{ 
                        Name       = $User.name
                        UserName   = $User.username
                        Email      = $User.email
                        UserId     = $_Userid
                        Type       = $User.type
                        Permission = $permidenum[$User.permissions]
                        LastLogin  = $origin.AddSeconds($User.lastlogin).ToLocalTime()
                        SessionId  = $session.SessionId
                    }
                }
            }
            else {
                Write-PSFMessage -Level Warning -Message "Server for session $($connection.sessionid) is not licenced for multiple users."
            }
        }
    }
}