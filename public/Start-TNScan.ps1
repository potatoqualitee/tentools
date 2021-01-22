function Start-TNScan {
    <#
    .SYNOPSIS
        Starts a list of scans

    .DESCRIPTION
        Starts a list of scans

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER ScanId
        The ID of the target scan

    .PARAMETER AlternateTarget
        Description for AlternateTarget

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Start-TNScan

        Starts a list of scans

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        # Nessus session Id
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("id")]
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
        foreach ($session in $SessionObject) {
            if ($session.sc) {
                $params = @{
                    SessionObject   = $session
                    EnableException = $EnableException
                    Path            = "/scan/$ScanId/launch"
                    Method          = "POST"
                    Parameter       = $paramJson
                }
                (Invoke-TNRequest @params).ScanResult | ConvertFrom-TNRestResponse
            } else {
                foreach ($scans in (Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/scans/$ScanId/launch" -Method POST -Parameter $paramJson -ContentType "application/json")) {
                    [pscustomobject]@{
                        ScanUUID  = $scans.scan_uuid
                        ScanId    = $ScanId
                        SessionId = $session.SessionId
                    }
                }
            }
        }
    }
}