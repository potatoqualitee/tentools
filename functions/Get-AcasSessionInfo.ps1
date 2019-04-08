function Get-AcasSessionInfo {
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
        $connections = $Global:NessusConn
        $ToProcess = New-Object -TypeName System.Collections.ArrayList

        foreach ($i in $SessionId) {
            Write-Verbose "Removing server session $($i)"

            foreach ($Connection in $connections) {
                if ($Connection.SessionId -eq $i) {
                    [void]$ToProcess.Add($Connection)
                }
            }

            foreach ($Connection in $ToProcess) {
                $RestMethodParams = @{
                    'Method'        = 'Get'
                    'URI'           = "$($connection.URI)/session"
                    'Headers'       = @{'X-Cookie' = "token=$($Connection.Token)"}
                    'ErrorVariable' = 'NessusSessionError'
                }
                $SessInfo = Invoke-RestMethod @RestMethodParams
                if ($SessInfo -is [psobject]) {
                    $SessionProps = [ordered]@{}
                    $SessionProps.Add('Id', $SessInfo.id)
                    $SessionProps.Add('Name', $SessInfo.name)
                    $SessionProps.Add('UserName', $SessInfo.UserName)
                    $SessionProps.Add('Email', $SessInfo.Email)
                    $SessionProps.Add('Type', $SessInfo.Type)
                    $SessionProps.Add('Permission', $PermissionsId2Name[$SessInfo.permissions])
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