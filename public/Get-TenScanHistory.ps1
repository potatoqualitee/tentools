function Get-TNScanHistory {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER ScanId
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TN

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
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
            foreach ($ScanDetails in (Invoke-TNRequest -SessionObject $session -Path "/scans/$ScanId" -Method GET -Parameter $params).history) {
                [pscustomobject]@{
                    HistoryId        = $History.history_id
                    UUID             = $History.uuid
                    Status           = $History.status
                    Type             = $History.type
                    CreationDate     = $origin.AddSeconds($History.creation_date).ToLocalTime()
                    LastModifiedDate = $origin.AddSeconds($History.last_modification_date).ToLocalTime()
                    SessionId        = $session.SessionId
                }
            }
        }
    }
}