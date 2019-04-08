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
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [Parameter(Mandatory, Position = 2, ValueFromPipelineByPropertyName)]
        [int32]$HistoryId
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
            Write-PSFMessage -Level Verbose -Mesage "Removing history Id ($HistoryId) from scan Id $($ScanId)"

            $ScanHistoryDetails = InvokeNessusRestRequest -SessionObject $Connection -Path "/scans/$($ScanId)/history/$($HistoryId)" -Method 'Delete' -Parameter $Params

            if ($ScanHistoryDetails -eq '') {
                Write-PSFMessage -Level Verbose -Mesage 'History Removed'
            }
        }
    }
}