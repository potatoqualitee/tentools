function Show-AcasScanHostDetail {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER ScanId
    Parameter description

    .PARAMETER HostId
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
        $HostId,

        [Parameter(Mandatory = $false,
            Position = 3,
            ValueFromPipelineByPropertyName = $true)]
        [Int32]
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
        $Params = @{}

        if ($HistoryId) {
            $Params.Add('history_id', $HistoryId)
        }

        foreach ($Connection in $ToProcess) {
            $ScanDetails = InvokeNessusRestRequest -SessionObject $Connection -Path "/scans/$($ScanId)/hosts/$($HostId)" -Method 'Get' -Parameter $Params

            if ($ScanDetails -is [psobject]) {
                $HostProps = [ordered]@{}
                $HostProps.Add('Info', $ScanDetails.info)
                $HostProps.Add('Vulnerabilities', $ScanDetails.vulnerabilities)
                $HostProps.Add('Compliance', $ScanDetails.compliance)
                $HostProps.Add('ScanId', $ScanId)
                $HostProps.Add('SessionId', $Connection.SessionId)
                $HostObj = New-Object -TypeName psobject -Property $HostProps
                $HostObj.pstypenames[0] = 'Nessus.Scan.HostDetails'
                $HostObj
            }
        }
    }
}