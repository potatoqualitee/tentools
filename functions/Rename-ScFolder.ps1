function Rename-ScFolder {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-ScService.

    .PARAMETER FolderId
        Parameter description

    .PARAMETER Name
        Parameter description

    .EXAMPLE
        PS> Get-Sc
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
        foreach ($session in (Get-ScSession -SessionId $SessionId)) {
            Invoke-ScRequest -SessionObject $session -Path "/folders/$($FolderId)" -Method 'PUT' -Parameter @{'name' = $Name }
        }
    }
}