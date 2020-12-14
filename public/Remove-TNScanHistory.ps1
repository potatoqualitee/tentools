function Remove-TNScanHistory {
    <#
    .SYNOPSIS
        Removes a list of scan histories

    .DESCRIPTION
        Removes a list of scan histories

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
        PS C:\> Remove-TNScanHistory

        Removes a list of scan histories

#>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$HistoryId,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            Write-PSFMessage -Level Verbose -Message "Removing history Id ($HistoryId) from scan Id $ScanId"
            Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/scans/$ScanId/history/$HistoryId" -Method Delete -Parameter $params | ConvertFrom-TNRestResponse
            Write-PSFMessage -Level Verbose -Message 'History Removed'
        }
    }
}