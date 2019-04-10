function Rename-AcasFolder {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER FolderId
        Parameter description

    .PARAMETER Name
        Parameter description

    .EXAMPLE
        PS> Get-Acas
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
        [string]$Name,
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
            $Folder = Invoke-AcasRequest -SessionObject $session -Path "/folders/$($FolderId)" -Method 'PUT' -Parameter @{'name' = $Name}
        }
    }
}