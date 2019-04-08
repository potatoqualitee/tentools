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
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Index')]
        [int32[]]
        $SessionId,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true)]
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
            Write-Verbose -Message "Deleting policy with id $($PolicyId)."
            $RemovedPolicy = InvokeNessusRestRequest -SessionObject $Connection -Path "/policies/$($PolicyId)" -Method 'DELETE'
            Write-Verbose -Message 'Policy deleted.'
        }
    }
    end {
    }
}