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
        [int32[]]$SessionId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1)]
        [Int32]$GroupId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 2)]
        [Int32]$UserId
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
                    'Path'          = "/groups/$($GroupId)/users"
                    'Method'        = 'POST'
                    'Parameter'     = @{'user_id' = $UserId}
                }

                InvokeNessusRestRequest @GroupParams
            } else {
                Write-PSFMessage -Level Warning -Mesage "Server for session $($Connection.sessionid) is not licenced for multiple users."
            }
        }
    }
}