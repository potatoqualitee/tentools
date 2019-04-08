function Get-AcasGroup {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    [OutputType([int])]
    param
    (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32]$SessionId
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
                    'Path'          = '/groups'
                    'Method'        = 'GET'
                }

                $Groups = InvokeNessusRestRequest @GroupParams
                foreach ($Group in $Groups.groups) {
                    $GroupProps = [ordered]@{}
                    $GroupProps.Add('Name', $Group.name)
                    $GroupProps.Add('GroupId', $Group.id)
                    $GroupProps.Add('Permissions', $Group.permissions)
                    $GroupProps.Add('UserCount', $Group.user_count)
                    $GroupProps.Add('SessionId', $Connection.SessionId)
                    $GroupObj = [PSCustomObject]$GroupProps
                    $GroupObj.pstypenames.insert(0, 'Nessus.Group')
                    $GroupObj
                }
            } else {
                Write-PSFMessage -Level Warning -Mesage "Server for session $($Connection.sessionid) is not licenced for multiple users."
            }
        }
    }
}