function Stop-AcasScan {
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
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$ScanId
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

        foreach ($Connection in $ToProcess) {
            $Scans = InvokeNessusRestRequest -SessionObject $Connection -Path "/scans/$($ScanId)/stop" -Method 'Post'

            if ($Scans -is [psobject]) {
                $scan = $Scans.scan
                $ScanProps = [ordered]@{}
                $ScanProps.add('Name', $scan.name)
                $ScanProps.add('ScanId', $ScanId)
                $ScanProps.add('HistoryId', $scan.id)
                $ScanProps.add('Status', $scan.status)
                $ScanProps.add('Enabled', $scan.enabled)
                $ScanProps.add('Owner', $scan.owner)
                $ScanProps.add('AlternateTarget', $scan.ownalt_targetser)
                $ScanProps.add('IsPCI', $scan.is_pci)
                $ScanProps.add('UserPermission', $PermissionsId2Name[$scan.user_permissions])
                $ScanProps.add('CreationDate', $origin.AddSeconds($scan.creation_date).ToLocalTime())
                $ScanProps.add('LastModified', $origin.AddSeconds($scan.last_modification_date).ToLocalTime())
                $ScanProps.add('StartTime', $origin.AddSeconds($scan.starttime).ToLocalTime())
                $ScanProps.Add('SessionId', $Connection.SessionId)
                $ScanObj = New-Object -TypeName psobject -Property $ScanProps
                $ScanObj.pstypenames[0] = 'Nessus.RunningScan'
                $ScanObj
            }
        }
    }
}