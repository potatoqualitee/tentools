function Get-TNScanHistory {
    <#
    .SYNOPSIS
        Gets a list of scan histories

    .DESCRIPTION
        Gets a list of scan histories

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
        PS C:\> Get-TNScanHistory -ScanId 50

        Gets a list of scan histories for scan with ID 50

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
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
        foreach ($session in $SessionObject) {
            if ($session.sc) {
                Stop-PSFFunction -Message "tenable.sc not supported" -Continue
            }

            if ($HistoryId) {
                $scan = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/scans/$ScanId" -Method GET -Parameter $params
            } else {
                $scan = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/scans/$ScanId" -Method GET
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