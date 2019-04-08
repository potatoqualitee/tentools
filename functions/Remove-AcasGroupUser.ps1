function Remove-AcasGroupUser {
    <#
    .SYNOPSIS
    Removes a Nessus group user

    .DESCRIPTION
    Can be used to clear a previously defined, scan report altering rule

    .PARAMETER SessionId
    ID of a valid Nessus session

    .PARAMETER Id
    ID number of the rule which would you like removed/deleted

    .EXAMPLE
    Remove-AcasGroupUser -SessionId 0 -Id 500
    Will delete a group user with an ID of 500

    .EXAMPLE
    Get-AcasPluginRule -SessionId 0 | Remove-AcasGroupUser
    Will delete all rules

    .EXAMPLE
    Get-AcasPluginRule -SessionId 0 | ? {$_.Host -eq 'myComputer'} | Remove-AcasGroupUser
    Will find all group users that match the computer name, and delete them

    .INPUTS
    Can accept pipeline data from Get-AcasPluginRule

    .OUTPUTS
    Empty, unless an error is received from the server
    #>
    [CmdletBinding()]
    param
    (
        # Nessus session Id
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Index')]
        [int32[]]
        $SessionId,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [Int32]
        $GroupId,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [Int32]
        $UserId
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
                    'Path'          = "/groups/$($GroupId)/users/$($UserId)"
                    'Method'        = 'DELETE'
                }

                InvokeNessusRestRequest @GroupParams
            } else {
                Write-Warning -message "Server for session $($Connection.sessionid) is not licenced for multiple users."
            }
        }
    }
}