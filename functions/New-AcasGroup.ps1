function New-AcasGroup {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER Name
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
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $Global:NessusConn.SessionId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1)]
        [string]$Name
    )

    begin {
        foreach ($i in $SessionId) {
            $connections = $Global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $i) {
                    $ToProcess += $connection
                }
            }
        }
    }
    process {
        foreach ($connection in $ToProcess) {
            $ServerTypeParams = @{
                'SessionObject' = $connection
                'Path'          = '/server/properties'
                'Method'        = 'GET'
            }

            $Server = InvokeNessusRestRequest @ServerTypeParams

            if ($Server.capabilities.multi_user -eq 'full') {
                $Groups = InvokeNessusRestRequest -SessionObject $connection -Path '/groups' -Method 'POST' -Parameter @{'name' = $Name}
                $NewGroupProps = [ordered]@{}
                $NewGroupProps.Add('Name', $Groups.name)
                $NewGroupProps.Add('GroupId', $Groups.id)
                $NewGroupProps.Add('Permissions', $Groups.permissions)
                $NewGroupProps.Add('SessionId', $connection.SessionId)
                $NewGroupObj = [pscustomobject]$NewGroupProps
                $NewGroupObj
            } else {
                Write-PSFMessage -Level Warning -Mesage "Server for session $($connection.sessionid) is not licenced for multiple users."
            }
        }
    }
}