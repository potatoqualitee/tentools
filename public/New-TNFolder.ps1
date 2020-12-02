function New-TNFolder {
<#
    .SYNOPSIS
        Creates new folders

    .DESCRIPTION
        Creates new folders
        
    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer
        
    .PARAMETER Name
        The name of the target folder
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> New-TNFolder

        Creates new folders
        
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if ($session.sc) {
                Stop-PSFFunction -Message "tenable.sc not supported" -Continue
            }
            foreach ($folder in $Name) {
                $result = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path '/folders' -Method POST -Parameter @{ "name" = "$folder" }
                if ($result) {
                    Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/folders" -Method GET | ConvertFrom-TNRestResponse | Where-Object Id -eq $result.id
                }
            }
        }
    }
}