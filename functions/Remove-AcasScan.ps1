function Remove-ScScan {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-ScService.

    .PARAMETER ScanId
        Parameter description

    .EXAMPLE
        PS> Get-Sc

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-ScSession -SessionId $SessionId)) {
            Write-PSFMessage -Level Verbose -Message "Removing scan with Id $($ScanId)"
            Invoke-ScRequest -SessionObject $session -Path "/scans/$($ScanId)" -Method 'Delete' -Parameter $params
            Write-PSFMessage -Level Verbose -Message 'Scan Removed'
        }
    }
}