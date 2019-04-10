function Show-AcasGroupMember {
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

    begin {
        foreach ($id in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $id) {
                    $collection += $session
                }
            }
        }

        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    }
    process {
        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            $ServerTypeParams = @{
                SessionObject = $session
                Path          = '/server/properties'
                Method        = 'GET'
            }

            $Server = Invoke-AcasRequest @ServerTypeParams

            if ($Server.capabilities.multi_user -eq 'full') {
                $GroupParams = @{
                    SessionObject = $session
                    Path          = "/groups/$($GroupId)/users"
                    Method        = 'GET '
                }

                $GroupMembers = Invoke-AcasRequest @GroupParams
                foreach ($User in $GroupMembers.users) {
                    $UserProperties = [ordered]@{}
                    $UserProperties.Add('Name', $User.name)
                    $UserProperties.Add('UserName', $User.username)
                    $UserProperties.Add('Email', $User.email)
                    $UserProperties.Add('UserId', $_Userid)
                    $UserProperties.Add('Type', $User.type)
                    $UserProperties.Add('Permission', $permidenum[$User.permissions])
                    $UserProperties.Add('LastLogin', $origin.AddSeconds($User.lastlogin).ToLocalTime())
                    $UserProperties.Add('SessionId', $session.SessionId)
                    $UserObj = New-Object -TypeName psobject -Property $UserProperties
                    $UserObj.pstypenames[0] = 'Nessus.User'
                    $UserObj
                }
            } else {
                Write-PSFMessage -Level Warning -Mesage "Server for session $($connection.sessionid) is not licenced for multiple users."
            }
        }
    }
}