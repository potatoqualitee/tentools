function Suspend-TNScan {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER ScanId
        Parameter description

    .EXAMPLE
        PS> Get-TN
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            foreach ($scan in (Invoke-TNRequest -SessionObject $session -Path "/scans/$ScanId/pause" -Method 'Post').scan) {
                [pscustomobject]@{
                    Name            = $scan.name
                    ScanId          = $ScanId
                    HistoryId       = $scan.id
                    Status          = $scan.status
                    Enabled         = $scan.enabled
                    Owner           = $scan.owner
                    AlternateTarget = $scan.ownalt_targetser
                    IsPCI           = $scan.is_pci
                    UserPermission  = $permidenum[$scan.user_permissions]
                    CreationDate    = $origin.AddSeconds($scan.creation_date).ToLocalTime()
                    LastModified    = $origin.AddSeconds($scan.last_modification_date).ToLocalTime()
                    StartTime       = $origin.AddSeconds($scan.starttime).ToLocalTime()
                    SessionId       = $session.SessionId
                }
            }
        }
    }
}