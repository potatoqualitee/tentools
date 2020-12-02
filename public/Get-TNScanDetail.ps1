function Get-TNScanDetail {
<#
    .SYNOPSIS
        Gets a list of scan details

    .DESCRIPTION
        Gets a list of scan details
        
    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer
        
    .PARAMETER ScanId
        The ID of the target scan
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> Get-TNScanDetail

        Gets a list of scan details
        
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("Id")]
        [int32]$ScanId,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $scan = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/scans/$ScanId" -Method GET
            if ($scan.info) {
                $scan.info | ConvertFrom-TNRestResponse
            } else {
                $scan | ConvertFrom-TNRestResponse
            }
        }
    }
}