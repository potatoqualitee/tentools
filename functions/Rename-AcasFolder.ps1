function Rename-AcasFolder {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER FolderId
    Parameter description

    .PARAMETER Name
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Int]$FolderId,
        [Parameter(Mandatory, Position = 2, ValueFromPipelineByPropertyName)]
        [string]$Name
    )
    process {
        $collection = @()

        foreach ($i in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $i) {
                    $collection += $connection
                }
            }
        }

        foreach ($connection in $collection) {
            $Folder = InvokeNessusRestRequest -SessionObject $connection -Path "/folders/$($FolderId)" -Method 'PUT' -Parameter @{'name' = $Name}
        }
    }
}