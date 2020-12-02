function Rename-TNFolder {
<#
    .SYNOPSIS
        Renames a list of folders

    .DESCRIPTION
        Renames a list of folders
        
    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer
        
    .PARAMETER FolderId
        Description for FolderId
        
    .PARAMETER Name
        The name of the target folder
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> Rename-TNFolder

        Renames a list of folders
        
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Int]$FolderId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/folders/$($FolderId)" -Method 'PUT' -Parameter @{'name' = $Name }
        }
    }
}