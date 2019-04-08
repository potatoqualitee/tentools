function Get-AcasScan {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER FolderId
    Parameter description

    .PARAMETER Status
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]
        $SessionId,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$FolderId,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
        [ValidateSet('Completed', 'Imported', 'Running', 'Paused', 'Canceled')]
        [string]$Status
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

        if ($FolderId) {
            $Params.Add('folder_id', $FolderId)
        }

        foreach ($Connection in $ToProcess) {
            $Scans = InvokeNessusRestRequest -SessionObject $Connection -Path '/scans' -Method 'Get' -Parameter $Params

            if ($Scans -is [psobject]) {

                if ($Status.length -gt 0) {
                    $Scans2Process = $Scans.scans | Where-Object {$_.status -eq $Status.ToLower()}
                } else {
                    $Scans2Process = $Scans.scans
                }
                foreach ($scan in $Scans2Process) {
                    $ScanProps = [ordered]@{}
                    $ScanProps.add('Name', $scan.name)
                    $ScanProps.add('ScanId', $scan.id)
                    $ScanProps.add('Status', $scan.status)
                    $ScanProps.add('Enabled', $scan.enabled)
                    $ScanProps.add('FolderId', $scan.folder_id)
                    $ScanProps.add('Owner', $scan.owner)
                    $ScanProps.add('UserPermission', $PermissionsId2Name[$scan.user_permissions])
                    $ScanProps.add('Rules', $scan.rrules)
                    $ScanProps.add('Shared', $scan.shared)
                    $ScanProps.add('TimeZone', $scan.timezone)
                    $ScanProps.add('Scheduled', $scan.control)
                    $ScanProps.add('DashboardEnabled', $scan.use_dashboard)
                    $ScanProps.Add('SessionId', $Connection.SessionId)
                    $ScanProps.add('CreationDate', $origin.AddSeconds($scan.creation_date).ToLocalTime())
                    $ScanProps.add('LastModified', $origin.AddSeconds($scan.last_modification_date).ToLocalTime())

                    if ($scan.starttime -cnotlike "*T*") {
                        $ScanProps.add('StartTime', $origin.AddSeconds($scan.starttime).ToLocalTime())
                    } else {
                        $StartTime = [datetime]::ParseExact($scan.starttime, "yyyyMMddTHHmmss",
                            [System.Globalization.CultureInfo]::InvariantCulture,
                            [System.Globalization.DateTimeStyles]::None)
                        $ScanProps.add('StartTime', $StartTime)
                    }
                    $ScanObj = New-Object -TypeName psobject -Property $ScanProps
                    $ScanObj.pstypenames[0] = 'Nessus.Scan'
                    $ScanObj
                }
            }
        }
    }
}