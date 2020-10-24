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
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("Id")]
        [int32]$ScanId,
        [int32]$HistoryId,
        [switch]$EnableException
    )
    begin {
        if ($HistoryId) {
            $params = @{
                history_id = $HistoryId
            }
        }
    }
    process {
        foreach ($session in (Get-TNSession)) {
            if ($session.sc) {
                Stop-PSFFunction -Message "tenable.sc not supported" -Continue
            }

            if ($HistoryId) {
                $scan = Invoke-TNRequest -SessionObject $session -Path "/scans/$ScanId" -Method GET -Parameter $params
            } else {
                $scan = Invoke-TNRequest -SessionObject $session -Path "/scans/$ScanId" -Method GET
            }
            if ($scan.history) {
                $script:includeid = $ScanId
                $scan.history | ConvertFrom-TNRestResponse
            }
        }
    }
    end {
        $script:includeid = $null
    }
}