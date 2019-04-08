function Remove-AcasGroup {
    ##
    
    [CmdletBinding()]
    param
    (
        # Nessus session Id
        [Parameter(Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]
        $SessionId,

        [Parameter(Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Int32]
        $GroupId
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
                    'Path'          = "/groups/$($GroupId)"
                    'Method'        = 'DELETE '
                }

                InvokeNessusRestRequest @GroupParams
            } else {
                Write-PSFMessage -Level Warning -Mesage "Server for session $($Connection.sessionid) is not licenced for multiple users."
            }
        }
    }
}