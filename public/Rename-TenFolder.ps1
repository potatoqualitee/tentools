function Rename-TenFolder {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER FolderId
        Parameter description

    .PARAMETER Name
        Parameter description

    .EXAMPLE
        PS> Get-Ten
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Int]$FolderId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TenSession)) {
            Invoke-TenRequest -SessionObject $session -Path "/folders/$($FolderId)" -Method 'PUT' -Parameter @{'name' = $Name }
        }
    }
}