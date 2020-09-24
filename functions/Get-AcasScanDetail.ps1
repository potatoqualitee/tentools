function Get-AcasScanDetail {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER ScanId
        Parameter description

    .PARAMETER HistoryId
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Acas
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $script:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
        [int32]$HistoryId,
        [switch]$EnableException
    )
    begin {
        $params = @{ }

        if ($HistoryId) {
            $params.Add('history_id', $HistoryId)
        }
    }
    process {
        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            foreach ($detail in (Invoke-AcasRequest -SessionObject $session -Path "/scans/$($ScanId)" -Method 'Get' -Parameter $params)) {
                $hosts = @()
                $history = @()

                # process host info.
                foreach ($hostdetail in $detail.hosts) {
                    $hosts += [pscustomobject]@{
                        HostName = $hostdetail.hostname
                        HostId   = $hostdetail.host_id
                        Critical = $hostdetail.critical
                        High     = $hostdetail.high
                        Medium   = $hostdetail.medium
                        Low      = $hostdetail.low
                        Info     = $hostdetail.info
                    }
                }
                # process history info.
                foreach ($ScanHistory in $detail.history) {
                    $history += [pscustomobject]@{
                        HistoryId        = $ScanHistory.history_id
                        Uuid             = $ScanHistory.uuid
                        Status           = $ScanHistory.status
                        Type             = $ScanHistory.type
                        CreationDate     = $origin.AddSeconds($ScanHistory.creation_date).ToLocalTime()
                        LastModifiedDate = $origin.AddSeconds($ScanHistory.last_modification_date).ToLocalTime()
                    }
                }

                # process Scan Info
                [pscustomobject]@{
                    Name                = $detail.info.name
                    ScanId              = $detail.info.object_id
                    Status              = $detail.info.status
                    uuid                = $detail.info.uuid
                    Policy              = $detail.info.policy
                    FolderId            = $detail.info.folder_id
                    ScannerName         = $detail.info.scanner_name
                    Hosts               = $hosts
                    HostCount           = $detail.info.hostcount
                    History             = $history
                    Targets             = $detail.info.targets
                    AlternetTargetsUsed = $detail.info.alt_targets_used
                    HasAuditTrail       = $detail.info.hasaudittrail
                    HasKb               = $detail.info.haskb
                    ACL                 = $detail.info.acls
                    Permission          = $permidenum[$detail.info.user_permissions]
                    EditAllowed         = $detail.info.edit_allowed
                    LastModified        = $origin.AddSeconds($detail.info.timestamp).ToLocalTime()
                    ScanStart           = $origin.AddSeconds($detail.info.scan_start).ToLocalTime()
                    SessionId           = $session.SessionId
                }
            }
        }
    }
}