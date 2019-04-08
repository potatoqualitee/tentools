function Remove-AcasScan {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER ScanId
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId,
        [Parameter(Mandatory,Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$ScanId
    )

    process {
        $ToProcess = @()

        foreach ($i in $SessionId) {
            $Connections = $Global:NessusConn

            foreach ($Connection in $Connections) {
                if ($Connection.SessionId -eq $i) {
                    $ToProcess += $Connection
                }
            }
        }

        foreach ($Connection in $ToProcess) {
            Write-PSFMessage -Level Verbose -Mesage "Removing scan with Id $($ScanId)"

            $ScanDetails = InvokeNessusRestRequest -SessionObject $Connection -Path "/scans/$($ScanId)" -Method 'Delete' -Parameter $Params
            if ($ScanDetails -eq 'null') {
                Write-PSFMessage -Level Verbose -Mesage 'Scan Removed'
            }
        }
    }
}