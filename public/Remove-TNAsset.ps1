function Remove-TNAsset {
    <#
    .SYNOPSIS
        Removes an asset

    .DESCRIPTION
        Removes an asset

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER AssetId
        The ID of the target asset

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNAsset | Remove-TNAsset

        Removes a list of assets

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("Id")]
        [int32[]]$AssetId,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            foreach ($id in $AssetId) {
                Write-PSFMessage -Level Verbose -Message "Deleting asset with id $id"
                Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/asset/$id" -Method Delete | ConvertFrom-TNRestResponse
                Write-PSFMessage -Level Verbose -Message 'Asset deleted'
            }
        }
    }
}