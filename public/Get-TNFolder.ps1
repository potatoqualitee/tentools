function Get-TNFolder {
<#
    .SYNOPSIS
        Gets a list of folders

    .DESCRIPTION
        Gets a list of folders
        
    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> Get-TNFolder

        Gets a list of folders
        
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if ($session.sc) {
                Stop-PSFFunction -Message "tenable.sc not supported" -Continue
            }
            Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path '/folders' -Method GET |
                ConvertFrom-TNRestResponse
        }
    }
}