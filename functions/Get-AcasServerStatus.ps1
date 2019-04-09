function Get-AcasServerStatus {
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
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = @()
    )
    process {
        $collection = @()

        foreach ($i in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $i) {
                    $collection += $connection
                }
            }
        }

        foreach ($connection in $collection) {

            $ServerStatus = InvokeNessusRestRequest -SessionObject $connection -Path '/server/status' -Method 'Get'

            if ($ServerStatus -is [psobject]) {
                $ServerStatus.pstypenames[0] = 'Nessus.ServerStatus'
                $ServerStatus
            }
        }
    }
}