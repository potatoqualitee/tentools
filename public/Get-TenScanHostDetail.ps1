function Get-TNScanHostDetail {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER ScanId
        Parameter description

    .PARAMETER HostId
        Parameter description

    .PARAMETER HistoryId
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TNScanHostDetail
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$HostId,
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
            foreach ($detail in (Invoke-TNRequest -SessionObject $session -Path "/scans/$ScanId/hosts/$($HostId)" -Method GET -Parameter $params)) {
                [pscustomobject]@{
                    Info            = $detail.info
                    Vulnerabilities = $detail.vulnerabilities
                    Compliance      = $detail.compliance
                    ScanId          = $ScanId
                    SessionId       = $session.SessionId
                }
            }
        }
    }
}