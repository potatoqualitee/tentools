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
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Int]$FolderId
    )
    process {
        $ToProcess = @()

        foreach ($i in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $i) {
                    $ToProcess += $connection
                }
            }
        }

        foreach ($connection in $ToProcess) {
            $Folder = InvokeNessusRestRequest -SessionObject $connection -Path "/folders/$($FolderId)" -Method 'DELETE'
        }
    }
}