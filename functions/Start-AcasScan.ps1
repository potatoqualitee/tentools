function Start-AcasScan {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER ScanId
    Parameter description

    .PARAMETER AlternateTarget
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    param
    (
        # Nessus session Id
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
        [string[]]$AlternateTarget
    )

    begin {
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
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
        $Params = @{}

        if ($AlternateTarget) {
            $Params.Add('alt_targets', $AlternateTarget)
        }
        $paramJson = ConvertTo-Json -InputObject $params -Compress

        foreach ($Connection in $ToProcess) {
            $Scans = InvokeNessusRestRequest -SessionObject $Connection -Path "/scans/$($ScanId)/launch" -Method 'Post' -Parameter $paramJson -ContentType 'application/json'

            if ($Scans -is [psobject]) {

                $ScanProps = [ordered]@{}
                $ScanProps.add('ScanUUID', $scans.scan_uuid)
                $ScanProps.add('ScanId', $ScanId)
                $ScanProps.add('SessionId', $Connection.SessionId)
                $ScanObj = New-Object -TypeName psobject -Property $ScanProps
                $ScanObj.pstypenames[0] = 'Nessus.LaunchedScan'
                $ScanObj
            }
        }
    }
}