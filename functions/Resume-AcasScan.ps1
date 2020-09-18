function Resume-AcasScan {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER ScanId
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Acas
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            foreach ($scan in (Invoke-AcasRequest -SessionObject $session -Path "/scans/$($ScanId)/resume" -Method 'Post').scan) {
                [pscustomobject]@{
                    Name            = $scan.name
                    ScanId          = $ScanId
                    HistoryId       = $scan.id
                    Status          = $scan.status
                    Enabled         = $scan.enabled
                    Owner           = $scan.owner
                    AlternateTarget = $scan.ownalt_targetser
                    IsPCI           = $scan.is_pci
                    UserPermission  = $permidenum[$scan.user_permissions]
                    CreationDate    = $origin.AddSeconds($scan.creation_date).ToLocalTime()
                    LastModified    = $origin.AddSeconds($scan.last_modification_date).ToLocalTime()
                    StartTime       = $origin.AddSeconds($scan.starttime).ToLocalTime()
                    SessionId       = $session.SessionId
                }
            }
        }
    }
}