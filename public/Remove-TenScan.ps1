function Remove-TenScan {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER ScanId
        Parameter description

    .EXAMPLE
        PS> Get-Ten

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TenSession)) {
            Write-PSFMessage -Level Verbose -Message "Removing scan with Id $ScanId"
            Invoke-TenRequest -SessionObject $session -Path "/scans/$ScanId" -Method 'Delete' -Parameter $params
            Write-PSFMessage -Level Verbose -Message 'Scan Removed'
        }
    }
}