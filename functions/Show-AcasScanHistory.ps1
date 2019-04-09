function Show-AcasScanHistory {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER ScanId
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
        [int32[]]$SessionId = $Global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$ScanId
    )

    begin {
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    }
    process {
        $ToProcess = @()

        foreach ($i in $SessionId) {
            $connections = $Global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $i) {
                    $ToProcess += $connection
                }
            }
        }
        $Params = @{}

        if ($HistoryId) {
            $Params.Add('history_id', $HistoryId)
        }

        foreach ($connection in $ToProcess) {
            $ScanDetails = InvokeNessusRestRequest -SessionObject $connection -Path "/scans/$($ScanId)" -Method 'Get' -Parameter $Params

            if ($ScanDetails -is [psobject]) {
                foreach ($History in $ScanDetails.history) {
                    $HistoryProps = [ordered]@{}
                    $HistoryProps['HistoryId'] = $History.history_id
                    $HistoryProps['UUID'] = $History.uuid
                    $HistoryProps['Status'] = $History.status
                    $HistoryProps['Type'] = $History.type
                    $HistoryProps['CreationDate'] = $origin.AddSeconds($History.creation_date).ToLocalTime()
                    $HistoryProps['LastModifiedDate'] = $origin.AddSeconds($History.last_modification_date).ToLocalTime()
                    $HistoryProps['SessionId'] = $connection.SessionId
                    $HistObj = New-Object -TypeName psobject -Property $HistoryProps
                    $HistObj.pstypenames[0] = 'Nessus.Scan.History'
                    $HistObj
                }
            }
        }
    }
}