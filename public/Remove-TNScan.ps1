function Remove-TNScan {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER ScanId
        Parameter description

    .EXAMPLE
        PS> Get-TN

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            Write-PSFMessage -Level Verbose -Message "Removing scan with Id $ScanId"
            Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/scans/$ScanId" -Method 'Delete' -Parameter $params
            Write-PSFMessage -Level Verbose -Message 'Scan Removed'
        }
    }
}