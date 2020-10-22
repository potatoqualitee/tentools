function Start-TNScan {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER ScanId
        Parameter description

    .PARAMETER AlternateTarget
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TN
    #>
    [CmdletBinding()]
    param
    (
        # Nessus session Id
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$AlternateTarget,
        [switch]$EnableException
    )
    begin {
        $params = @{ }

        if ($AlternateTarget) {
            $params.Add('alt_targets', $AlternateTarget)
        }
        $paramJson = ConvertTo-Json -InputObject $params -Compress
    }
    process {
        foreach ($session in (Get-TNSession)) {
            foreach ($scans in (Invoke-TNRequest -SessionObject $session -Path "/scans/$ScanId/launch" -Method 'Post' -Parameter $paramJson -ContentType 'application/json')) {
                [pscustomobject]@{
                    ScanUUID  = $scans.scan_uuid
                    ScanId    = $ScanId
                    SessionId = $session.SessionId
                }
            }
        }
    }
}