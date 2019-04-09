function Remove-AcasScanHistory {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER ScanId
        Parameter description

    .PARAMETER HistoryId
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Acas
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [Parameter(Mandatory, Position = 2, ValueFromPipelineByPropertyName)]
        [int32]$HistoryId,
        [switch]$EnableException
    )
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

        foreach ($connection in $collection) {
            Write-PSFMessage -Level Verbose -Mesage "Removing history Id ($HistoryId) from scan Id $($ScanId)"

            $ScanHistoryDetails = Invoke-AcasRequest -SessionObject $connection -Path "/scans/$($ScanId)/history/$($HistoryId)" -Method 'Delete' -Parameter $Params

            if ($ScanHistoryDetails -eq '') {
                Write-PSFMessage -Level Verbose -Mesage 'History Removed'
            }
        }
    }
}