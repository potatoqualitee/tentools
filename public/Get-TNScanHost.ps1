function Get-TNScanHost {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        Parameter description

    .PARAMETER ScanId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TNServer.

    .PARAMETER HistoryId
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TNScanHost
    #>
    [CmdletBinding()]
    Param
    (
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
        foreach ($session in (Get-TNSession)) {
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