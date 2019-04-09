function New-AcasFolder {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
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
        [int32[]]$SessionId = $Global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string]$Name
    )
    process {
        $ToProcess = @()

        foreach ($i in $SessionId) {
            $connections = $Global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $i) {
                    $ToProcess += $connection
                }
            }
        }

        foreach ($connection in $ToProcess) {
            $Folder = InvokeNessusRestRequest -SessionObject $connection -Path '/folders' -Method 'Post' -Parameter @{'name' = $Name}

            if ($Folder -is [psobject]) {
                Get-AcasFolder -SessionId $connection.sessionid | Where-Object {
                    $_.FolderId -eq $Folder.id
                }
            }
        }
    }
}