function Remove-NessusFolder {
    <#
    .SYNOPSIS

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    Param
    (
        # Nessus session Id
        [Parameter(Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]
        $SessionId,
        [Parameter(Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName)]
        [Int]
        $FolderId
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
            $Folder = InvokeNessusRestRequest -SessionObject $Connection -Path "/folders/$($FolderId)" -Method 'DELETE'
        }
    }
}