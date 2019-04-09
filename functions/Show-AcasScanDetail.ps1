function Show-AcasScanDetail {
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
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
        [int32]$HistoryId
    )

    begin {
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    }
    process {
        $collection = @()

        foreach ($id in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $id) {
                    $collection += $connection
                }
            }
        }
        $Params = @{}

        if ($HistoryId) {
            $Params.Add('history_id', $HistoryId)
        }

        foreach ($connection in $collection) {
            $ScanDetails = Invoke-AcasRequest -SessionObject $connection -Path "/scans/$($ScanId)" -Method 'Get' -Parameter $Params

            if ($ScanDetails -is [psobject]) {

                $ScanDetailProps = [ordered]@{}
                $hosts = @()
                $history = @()

                # process Scan Info
                $ScanInfo = [ordered]@{}
                $ScanInfo.add('Name', $ScanDetails.info.name)
                $ScanInfo.add('ScanId', $ScanDetails.info.object_id)
                $ScanInfo.add('Status', $ScanDetails.info.status)
                $ScanInfo.add('UUID', $ScanDetails.info.uuid)
                $ScanInfo.add('Policy', $ScanDetails.info.policy)
                $ScanInfo.add('FolderId', $ScanDetails.info.folder_id)
                $ScanInfo.add('ScannerName', $ScanDetails.info.scanner_name)
                $ScanInfo.add('HostCount', $ScanDetails.info.hostcount)
                $ScanInfo.add('Targets', $ScanDetails.info.targets)
                $ScanInfo.add('AlternetTargetsUsed', $ScanDetails.info.alt_targets_used)
                $ScanInfo.add('HasAuditTrail', $ScanDetails.info.hasaudittrail)
                $ScanInfo.add('HasKb', $ScanDetails.info.haskb)
                $ScanInfo.add('ACL', $ScanDetails.info.acls)
                $ScanInfo.add('Permission', $permidenum[$ScanDetails.info.user_permissions])
                $ScanInfo.add('EditAllowed', $ScanDetails.info.edit_allowed)
                $ScanInfo.add('LastModified', $origin.AddSeconds($ScanDetails.info.timestamp).ToLocalTime())
                $ScanInfo.add('ScanStart', $origin.AddSeconds($ScanDetails.info.scan_start).ToLocalTime())
                $ScanInfo.Add('SessionId', $connection.SessionId)
                $InfoObj = New-Object -TypeName psobject -Property $ScanInfo
                $InfoObj.pstypenames[0] = 'Nessus.Scan.Info'


                # process host info.
                foreach ($Host in $ScanDetails.hosts) {
                    $HostProps = [ordered]@{}
                    $HostProps.Add('HostName', $Host.hostname)
                    $HostProps.Add('HostId', $Host.host_id)
                    $HostProps.Add('Critical', $Host.critical)
                    $HostProps.Add('High', $Host.high)
                    $HostProps.Add('Medium', $Host.medium)
                    $HostProps.Add('Low', $Host.low)
                    $HostProps.Add('Info', $Host.info)
                    $HostObj = New-Object -TypeName psobject -Property $HostProps
                    $HostObj.pstypenames[0] = 'Nessus.Scan.Host'
                    $hosts += $HostObj
                }

                # process history info.
                foreach ($ScanHistory in $ScanDetails.history) {
                    $HistoryProps = [ordered]@{}
                    $HistoryProps['HistoryId'] = $ScanHistory.history_id
                    $HistoryProps['UUID'] = $ScanHistory.uuid
                    $HistoryProps['Status'] = $ScanHistory.status
                    $HistoryProps['Type'] = $ScanHistory.type
                    $HistoryProps['CreationDate'] = $origin.AddSeconds($ScanHistory.creation_date).ToLocalTime()
                    $HistoryProps['LastModifiedDate'] = $origin.AddSeconds($ScanHistory.last_modification_date).ToLocalTime()
                    $HistObj = New-Object -TypeName psobject -Property $HistoryProps
                    $HistObj.pstypenames[0] = 'Nessus.Scan.History'
                    $history += $HistObj
                }

                $ScanDetails
            }
        }
    }
}