function Start-AcasScan {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER ScanId
        Parameter description

    .PARAMETER AlternateTarget
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Acas
    #>
    [CmdletBinding()]
    param
    (
        # Nessus session Id
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
        [string[]]$AlternateTarget,
        [switch]$EnableException
    )

    begin {
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    }
    process {
        $collection = @()

        foreach ($id in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $id) {
                    $collection += $session
                }
            }
        }
        $params = @{ }

        if ($AlternateTarget) {
            $params.Add('alt_targets', $AlternateTarget)
        }
        $paramJson = ConvertTo-Json -InputObject $params -Compress

        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            $Scans = Invoke-AcasRequest -SessionObject $session -Path "/scans/$($ScanId)/launch" -Method 'Post' -Parameter $paramJson -ContentType 'application/json'

            if ($Scans -is [psobject]) {

                $ScanProps = [ordered]@{ }
                $ScanProps.add('ScanUUID', $scans.scan_uuid)
                $ScanProps.add('ScanId', $ScanId)
                $ScanProps.add('SessionId', $session.SessionId)
                $ScanObj = New-Object -TypeName psobject -Property $ScanProps
                $ScanObj.pstypenames[0] = 'Nessus.LaunchedScan'
                $ScanObj
            }
        }
    }
}