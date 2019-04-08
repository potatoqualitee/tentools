function Remove-AcasPolicy {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER PolicyId
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    Param
    (
        # Nessus session Id
        [Parameter(Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]
        $SessionId,

        [Parameter(Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName)]
        [int32]
        $PolicyId

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
            Write-PSFMessage -Level Verbose -Mesage "Deleting policy with id $($PolicyId)."
            $RemovedPolicy = InvokeNessusRestRequest -SessionObject $Connection -Path "/policies/$($PolicyId)" -Method 'DELETE'
            Write-PSFMessage -Level Verbose -Mesage 'Policy deleted.'
        }
    }
    end {
    }
}