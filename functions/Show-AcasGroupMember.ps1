function Show-AcasGroupMember {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER GroupId
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1)]
        [int32]$GroupId
    )

    begin {
        foreach ($i in $SessionId) {
            $Connections = $Global:NessusConn

            foreach ($Connection in $Connections) {
                if ($Connection.SessionId -eq $i) {
                    $ToProcess += $Connection
                }
            }
        }

        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    }
    process {
        foreach ($Connection in $ToProcess) {
            $ServerTypeParams = @{
                'SessionObject' = $Connection
                'Path'          = '/server/properties'
                'Method'        = 'GET'
            }

            $Server = InvokeNessusRestRequest @ServerTypeParams

            if ($Server.capabilities.multi_user -eq 'full') {
                $GroupParams = @{
                    'SessionObject' = $Connection
                    'Path'          = "/groups/$($GroupId)/users"
                    'Method'        = 'GET '
                }

                $GroupMembers = InvokeNessusRestRequest @GroupParams
                foreach ($User in $GroupMembers.users) {
                    $UserProperties = [ordered]@{}
                    $UserProperties.Add('Name', $User.name)
                    $UserProperties.Add('UserName', $User.username)
                    $UserProperties.Add('Email', $User.email)
                    $UserProperties.Add('UserId', $_Userid)
                    $UserProperties.Add('Type', $User.type)
                    $UserProperties.Add('Permission', $PermissionsId2Name[$User.permissions])
                    $UserProperties.Add('LastLogin', $origin.AddSeconds($User.lastlogin).ToLocalTime())
                    $UserProperties.Add('SessionId', $Connection.SessionId)
                    $UserObj = New-Object -TypeName psobject -Property $UserProperties
                    $UserObj.pstypenames[0] = 'Nessus.User'
                    $UserObj
                }
            } else {
                Write-PSFMessage -Level Warning -Mesage "Server for session $($Connection.sessionid) is not licenced for multiple users."
            }
        }
    }
}