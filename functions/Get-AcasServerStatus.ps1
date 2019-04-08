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
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Index')]
        [int32[]]
        $SessionId = @()
    )

    begin {
    }
    process {
        $ToProcess = @()

        foreach ($i in $SessionId) {
            $Connections = $Global:NessusConn

            foreach ($Connection in $Connections) {
                if ($Connection.SessionId -eq $i) {
                    $ToProcess += $Connection
                }
            }
        }

        foreach ($Connection in $ToProcess) {

            $ServerStatus = InvokeNessusRestRequest -SessionObject $Connection -Path '/server/status' -Method 'Get'

            if ($ServerStatus -is [psobject]) {
                $ServerStatus.pstypenames[0] = 'Nessus.ServerStatus'
                $ServerStatus
            }
        }
    }
    end {
    }
}