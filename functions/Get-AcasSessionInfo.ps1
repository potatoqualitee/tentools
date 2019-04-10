function Get-AcasSessionInfo {
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
        PS> Get-Acas
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [switch]$EnableException
    )
    begin {
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    }
    process {
        $connections = $global:NessusConn
        $collection = New-Object -TypeName System.Collections.ArrayList

        foreach ($id in $SessionId) {
            Write-Verbose "Removing server session $($id)"

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $id) {
                    [void]$collection.Add($connection)
                }
            }

            foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
                $RestMethodParams = @{
                    Method        = 'Get'
                    'URI'           = "$($connection.URI)/session"
                    'Headers'       = @{'X-Cookie' = "token=$($connection.Token)" }
                    'ErrorVariable' = 'NessusSessionError'
                }
                $SessInfo = Invoke-RestMethod @RestMethodParams
                if ($SessInfo -is [psobject]) {
                    $SessionProps = [ordered]@{ }
                    $SessionProps.Add('Id', $SessInfo.id)
                    $SessionProps.Add('Name', $SessInfo.name)
                    $SessionProps.Add('UserName', $SessInfo.UserName)
                    $SessionProps.Add('Email', $SessInfo.Email)
                    $SessionProps.Add('Type', $SessInfo.Type)
                    $SessionProps.Add('Permission', $permidenum[$SessInfo.permissions])
                    $SessionProps.Add('LastLogin', $origin.AddSeconds($SessInfo.lastlogin).ToLocalTime())
                    $SessionProps.Add('Groups', $SessInfo.groups)
                    $SessionProps.Add('Connectors', $SessInfo.connectors)

                    $SessInfoObj = New-Object -TypeName psobject -Property $SessionProps
                    $SessInfoObj.pstypenames[0] = 'Nessus.SessionInfo'
                    $SessInfoObj
                }
            }
        }
    }
}