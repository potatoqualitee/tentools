function Get-TNScanResult {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER ScanId
        Parameter description

    .PARAMETER HistoryId
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
        [Alias("Id")]
        [int32]$ScanId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            Invoke-TNRequest -SessionObject $session -Path "/scanResult" -Method GET
        }
    }
}