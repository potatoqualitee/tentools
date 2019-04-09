function Copy-AcasPolicy {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER PolicyId
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
        [int32]$PolicyId

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
            $CopiedPolicy = InvokeNessusRestRequest -SessionObject $connection -Path "/policies/$($PolicyId)/copy" -Method 'Post'
            [PSCustomObject]@{
                Name      = $CopiedPolicy.Name
                PolicyId  = $CopiedPolicy.Id
                SessionId = $connection.SessionId
            }
        }
    }
}