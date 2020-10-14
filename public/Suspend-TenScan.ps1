function Suspend-TenScan {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TenServer.

    .PARAMETER ScanId
        Parameter description

    .EXAMPLE
        PS> Get-Ten
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $script:NessusConn.SessionId,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TenSession -SessionId $SessionId)) {
            foreach ($scan in (Invoke-TenRequest -SessionObject $session -Path "/scans/$ScanId/pause" -Method 'Post').scan) {
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