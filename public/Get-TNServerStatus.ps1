function Get-TNServerStatus {
<#
    .SYNOPSIS
        Gets a list of server statuss

    .DESCRIPTION
        Gets a list of server statuss
        
    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> Get-TNServerStatus

        Gets a list of server statuss
        
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
            # only show if it's called from the command line
            if ((Get-PSCallStack).Count -eq 2 -and $session.sc) {
                Stop-PSFFunction -Message "tenable.sc not supported" -Continue
            }
            Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path '/server/status' -Method GET
        }
    }
}