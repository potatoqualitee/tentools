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
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $Global:NessusConn.SessionId,
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

                    if ($scan.starttime -cnotlike "*T*") {
                        $StartTime = $origin.AddSeconds($scan.starttime).ToLocalTime()
                    } else {
                        $StartTime = [datetime]::ParseExact($scan.starttime, "yyyyMMddTHHmmss",
                            [System.Globalization.CultureInfo]::InvariantCulture,
                            [System.Globalization.DateTimeStyles]::None)
                    }

                    [pscustomobject]@{
                        Name = $scan.name
                        ScanId = $scan.id
                        Status = $scan.status
                        Enabled = $scan.enabled
                        FolderId = $scan.folder_id
                        Owner = $scan.owner
                        UserPermission = $PermissionsId2Name[$scan.user_permissions]
                        Rules = $scan.rrules
                        Shared = $scan.shared
                        TimeZone = $scan.timezone
                        Scheduled = $scan.control
                        DashboardEnabled = $scan.use_dashboard
                        SessionId = $Connection.SessionId
                        CreationDate = $origin.AddSeconds($scan.creation_date).ToLocalTime()
                        LastModified = $origin.AddSeconds($scan.last_modification_date).ToLocalTime()
                        StartTime = $StartTime
                    }
                }
            }
        }
    }
}