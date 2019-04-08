function Rename-AcasGroup {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER GroupId
    Parameter description

    .PARAMETER Name
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
        [Int32]$GroupId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 2)]
        [string]$Name
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
                    'Method'        = 'PUT'
                    'ContentType'   = 'application/json'
                    'Parameter'     = (ConvertTo-Json -InputObject @{'name' = $Name} -Compress)
                }

                InvokeNessusRestRequest @GroupParams
            } else {
                Write-PSFMessage -Level Warning -Mesage "Server for session $($Connection.sessionid) is not licenced for multiple users."
            }
        }
    }
}