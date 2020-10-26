function Get-TNServerInfo {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TNServerInfo
    #>
    [CmdletBinding()]
    param
    (
        [int[]]$SessionId,
        [switch]$EnableException
    )
    foreach ($session in (Get-TNSession -SessionId $SessionId)) {
        # only show if it's called from the command line
        if ((Get-PSCallStack).Count -eq 2 -and $session.sc) {
            Stop-PSFFunction -Message "tenable.sc not supported" -Continue
        }
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
        $server = Invoke-TNRequest -SessionObject $session -Path '/server/properties' -Method GET
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