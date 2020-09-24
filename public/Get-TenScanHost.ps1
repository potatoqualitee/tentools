function Get-TenScanHost {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        Parameter description

    .PARAMETER ScanId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TenService.

    .PARAMETER HistoryId
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TenScanHost
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
        foreach ($session in (Get-TenSession -SessionId $SessionId)) {
            foreach ($Host in (Invoke-TenRequest -SessionObject $session -Path "/scans/$($ScanId)" -Method 'Get' -Parameter $params).hosts) {
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