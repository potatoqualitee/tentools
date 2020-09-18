function Get-AcasScan {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER FolderId
        Parameter description

    .PARAMETER Status
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Acas
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $script:NessusConn.SessionId,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$FolderId,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
        [ValidateSet('Completed', 'Imported', 'Running', 'Paused', 'Canceled')]
        [string]$Status,
        [switch]$EnableException
    )
    begin {
        $params = @{ }

        if ($FolderId) {
            $params.Add('folder_id', $FolderId)
        }
    }
    process {
        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            $scans = Invoke-AcasRequest -SessionObject $session -Path '/scans' -Method 'Get' -Parameter $params

            if ($Status.length -gt 0) {
                $allscans = $scans.scans | Where-Object { $_.status -eq $Status.ToLower() }
            }
            else {
                $allscans = $scans.scans
            }
            foreach ($scan in $allscans) {

                if ($scan.starttime -cnotlike "*T*") {
                    $StartTime = $origin.AddSeconds($scan.starttime).ToLocalTime()
                }
                else {
                    $StartTime = [datetime]::ParseExact($scan.starttime, "yyyyMMddTHHmmss",
                        [System.Globalization.CultureInfo]::InvariantCulture,
                        [System.Globalization.DateTimeStyles]::None)
                }

                [pscustomobject]@{
                    Name             = $scan.name
                    ScanId           = $scan.id
                    Status           = $scan.status
                    Enabled          = $scan.enabled
                    FolderId         = $scan.folder_id
                    Owner            = $scan.owner
                    UserPermission   = $permidenum[$scan.user_permissions]
                    Rules            = $scan.rrules
                    Shared           = $scan.shared
                    TimeZone         = $scan.timezone
                    Scheduled        = $scan.control
                    DashboardEnabled = $scan.use_dashboard
                    SessionId        = $session.SessionId
                    CreationDate     = $origin.AddSeconds($scan.creation_date).ToLocalTime()
                    LastModified     = $origin.AddSeconds($scan.last_modification_date).ToLocalTime()
                    StartTime        = $StartTime
                }
            }
        }
    }
}