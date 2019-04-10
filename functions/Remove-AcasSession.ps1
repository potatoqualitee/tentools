function Remove-AcasSession {
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
    param(
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [switch]$EnableException
    )
    process {
        # Finding and saving sessions in to a different Array so they can be
        # removed from the main one so as to not generate an modification
        # error for a collection in use.
        $connections = $global:NessusConn
        $toremove = New-Object -TypeName System.Collections.ArrayList

        if ($SessionId.Count -gt 0) {
            foreach ($id in $SessionId) {
                Write-PSFMessage -Level Verbose -Mesage "Removing server session $($id)"

                foreach ($connection in $connections) {
                    if ($connection.SessionId -eq $id) {
                        [void]$toremove.Add($connection)
                    }
                }
            }

            foreach ($connection in $toremove) {
                Write-PSFMessage -Level Verbose -Mesage 'Disposing of connection'
                $RestMethodParams = @{
                    Method        = 'Delete'
                    'URI'           = "$($connection.URI)/session"
                    'Headers'       = @{'X-Cookie' = "token=$($connection.Token)" }
                    'ErrorVariable' = 'DisconnectError'
                    'ErrorAction'   = 'SilentlyContinue'
                }
                try {
                    $RemoveResponse = Invoke-RestMethod @RestMethodParams
                }
                catch {
                    Write-PSFMessage -Level Verbose -Mesage "Session with Id $($connection.SessionId) seems to have expired."
                }
                
                Write-PSFMessage -Level Verbose -Mesage "Removing session from `$global:NessusConn"
                $global:NessusConn.Remove($connection)
                Write-PSFMessage -Level Verbose -Mesage "Session $($id) removed."
            }
        }
    }
}