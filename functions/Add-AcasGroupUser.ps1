function Add-AcasGroupUser {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    ID of a valid Nessus session

    .PARAMETER GroupId
    Parameter description

    .PARAMETER UserId
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param
    (
        # Nessus session Id
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1)]
        [Int32]$GroupId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 2)]
        [Int32]$UserId
    )

    begin {
        foreach ($i in $SessionId) {
            $connections = $global:NessusConn
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
                $GroupParams = @{
                    'SessionObject' = $connection
                    'Path'          = "/groups/$($GroupId)/users"
                    'Method'        = 'POST'
                    'Parameter'     = @{'user_id' = $UserId}
                }

                InvokeNessusRestRequest @GroupParams
            } else {
                Write-PSFMessage -Level Warning -Mesage "Server for session $($connection.sessionid) is not licenced for multiple users."
            }
        }
    }
}