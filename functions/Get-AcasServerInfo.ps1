function Get-AcasServerInfo {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-AcasServerInfo
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $script:NessusConn.SessionId,
        [switch]$EnableException
    )
    foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0$origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
        $server = Invoke-AcasRequest -SessionObject $session -Path '/server/properties' -Method 'Get'

        foreach ($serverinfo in $server) {
            [pscustomobject]@{ 
                NessusType     = $serverinfo.nessus_type
                ServerVersion  = $serverinfo.server_version
                UIVersion      = $serverinfo.nessus_ui_version
                PluginSet      = $serverinfo.loaded_plugin_set
                Feed           = $serverinfo.feed
                FeedExpiration = $origin.AddSeconds($serverinfo.expiration).ToLocalTime()
                Capabilities   = $serverinfo.capabilities
                UUID           = $serverinfo.server_uuid
                Update         = $serverinfo.update
                Enterprise     = $serverinfo.enterprise
                License        = $serverinfo.license
            }
        }
    }
}