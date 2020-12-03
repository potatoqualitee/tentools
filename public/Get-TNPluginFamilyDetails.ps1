function Get-TNPluginFamilyDetails {
<#
    .SYNOPSIS
        Gets a list of plugin family detailss

    .DESCRIPTION
        Gets a list of plugin family detailss
        
    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer
        
    .PARAMETER FamilyId
        The ID of the target family
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> Get-TNPluginFamilyDetails

        Gets a list of plugin family detailss
        
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int]$FamilyId,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            foreach ($detail in (Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/plugins/families/$($FamilyId)" -Method GET)) {
                [pscustomobject]@{
                    Name     = $detail.name
                    FamilyId = $detail.id
                    Plugins  = $detail.plugins
                }
            }
        }
    }
}