function Remove-AcasScanHistory {
    <#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER SessionId
Parameter description

.PARAMETER ScanId
Parameter description

.PARAMETER HistoryId
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
        $ScanId,

        [Parameter(Mandatory = $true,
            Position = 2,
            ValueFromPipelineByPropertyName = $true)]
        [int32]
        $HistoryId
    )
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
            Write-Verbose -Message "Removing history Id ($HistoryId) from scan Id $($ScanId)"

            $ScanHistoryDetails = InvokeNessusRestRequest -SessionObject $Connection -Path "/scans/$($ScanId)/history/$($HistoryId)" -Method 'Delete' -Parameter $Params

            if ($ScanHistoryDetails -eq '') {
                Write-Verbose -Message 'History Removed'
            }


        }
    }
}