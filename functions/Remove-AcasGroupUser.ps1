function Remove-AcasGroupUser {
    <#
    .SYNOPSIS
        Removes a Nessus group user

    .DESCRIPTION
        Can be used to clear a previously defined, scan report altering rule

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER Id
        ID number of the rule which would you like removed/deleted

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

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
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1)]
        [Int32]$GroupId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 2)]
        [Int32]$UserId,
        [switch]$EnableException
    )

    begin {
        foreach ($id in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $id) {
                    $collection += $connection
                }
            }
        }
    }
    process {
        foreach ($connection in $collection) {
            $ServerTypeParams = @{
                'SessionObject' = $connection
                'Path'          = '/server/properties'
                'Method'        = 'GET'
            }

            $Server = Invoke-AcasRequest @ServerTypeParams

            if ($Server.capabilities.multi_user -eq 'full') {
                $GroupParams = @{
                    'SessionObject' = $connection
                    'Path'          = "/groups/$($GroupId)/users/$($UserId)"
                    'Method'        = 'DELETE'
                }

                Invoke-AcasRequest @GroupParams
            }
            else {
                Write-PSFMessage -Level Warning -Mesage "Server for session $($connection.sessionid) is not licenced for multiple users."
            }
        }
    }
}