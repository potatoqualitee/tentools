function Show-AcasScanHost {
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
        [int32[]]$SessionId = $Global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
        [int32]$HistoryId
    )
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
                foreach ($Host in $ScanDetails.hosts) {
                    $HostProps = [ordered]@{}
                    $HostProps.Add('HostName', $Host.hostname)
                    $HostProps.Add('HostId', $Host.host_id)
                    $HostProps.Add('Critical', $Host.critical)
                    $HostProps.Add('High', $Host.high)
                    $HostProps.Add('Medium', $Host.medium)
                    $HostProps.Add('Low', $Host.low)
                    $HostProps.Add('Info', $Host.info)
                    $HostProps.Add('ScanId', $ScanId)
                    $HostProps.Add('SessionId', $connection.SessionId)
                    $HostObj = New-Object -TypeName psobject -Property $HostProps
                    $HostObj.pstypenames[0] = 'Nessus.Scan.Host'
                    $HostObj
                }
            }
        }
    }
}