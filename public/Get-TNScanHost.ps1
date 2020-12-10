function Get-TNScanHost {
    <#
    .SYNOPSIS
        Gets a list of scan hosts

    .DESCRIPTION
        Gets a list of scan hosts

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER ScanId
        The ID of the target scan

    .PARAMETER HistoryId
        The ID for the target history

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNScanHost -ScanId 50

        Gets the scan host for Id 50

#>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [Parameter(ValueFromPipelineByPropertyName)]
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
        foreach ($session in $SessionObject) {
            foreach ($Host in (Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/scans/$ScanId" -Method GET -Parameter $params).hosts) {
                [pscustomobject]@{
                    HostName  = $Host.hostname
                    HostId    = $Host.host_id
                    Critical  = $Host.critical
                    High      = $Host.high
                    Medium    = $Host.medium
                    Low       = $Host.low
                    Info      = $Host.info
                    ScanId    = $ScanId
                    SessionId = $session.SessionId
                }
            }
        }
    }
}