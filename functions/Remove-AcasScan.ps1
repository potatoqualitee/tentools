function Remove-AcasScan {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER ScanId
        Parameter description

    .EXAMPLE
        PS> Get-Acas

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory,Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [switch]$EnableException
    )
    process {
        $collection = @()

        foreach ($id in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $id) {
                    $collection += $session
                }
            }
        }

        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            Write-PSFMessage -Level Verbose -Message "Removing scan with Id $($ScanId)"

            $ScanDetails = Invoke-AcasRequest -SessionObject $session -Path "/scans/$($ScanId)" -Method 'Delete' -Parameter $params
            if ($ScanDetails -eq 'null') {
                Write-PSFMessage -Level Verbose -Message 'Scan Removed'
            }
        }
    }
}