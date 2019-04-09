function Get-AcasServerInfo {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = @()
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
                    $collection += $connection
                }
            }
        }

        foreach ($connection in $collection) {

            $ServerInfo = Invoke-AcasRequest -SessionObject $connection -Path '/server/properties' -Method 'Get'

            if ($ServerInfo -is [psobject]) {
                $SrvInfoProp = [ordered]@{}
                $SrvInfoProp.Add('NessusType', $ServerInfo.nessus_type)
                $SrvInfoProp.Add('ServerVersion', $ServerInfo.server_version)
                $SrvInfoProp.Add('UIVersion', $ServerInfo.nessus_ui_version)
                $SrvInfoProp.Add('PluginSet', $ServerInfo.loaded_plugin_set)
                $SrvInfoProp.Add('Feed', $ServerInfo.feed)
                $SrvInfoProp.Add('FeedExpiration', $origin.AddSeconds($ServerInfo.expiration).ToLocalTime())
                $SrvInfoProp.Add('Capabilities', $ServerInfo.capabilities)
                $SrvInfoProp.Add('UUID', $ServerInfo.server_uuid)
                $SrvInfoProp.Add('Update', $ServerInfo.update)
                $SrvInfoProp.Add('Enterprise', $ServerInfo.enterprise)
                $SrvInfoProp.Add('License', $ServerInfo.license)
                $SrvInfoObj = New-Object -TypeName psobject -Property $SrvInfoProp
                $SrvInfoObj.pstypenames[0] = 'Nessus.ServerInfo'
                $SrvInfoObj
            }
        }
    }
}