function Remove-AcasSession {

    [CmdletBinding()]
    param(

        # Nessus session Id
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Index')]
        [int32[]]
        $SessionId = @()
    )
    process {
        # Finding and saving sessions in to a different Array so they can be
        # removed from the main one so as to not generate an modification
        # error for a collection in use.
        $connections = $Global:NessusConn
        $toremove = New-Object -TypeName System.Collections.ArrayList

        if ($SessionId.Count -gt 0) {
            foreach ($i in $SessionId) {
                Write-Verbose -Message "Removing server session $($i)"

                foreach ($Connection in $connections) {
                    if ($Connection.SessionId -eq $i) {
                        [void]$toremove.Add($Connection)
                    }
                }
            }

            foreach ($Connection in $toremove) {
                Write-Verbose -Message 'Disposing of connection'
                $RestMethodParams = @{
                    'Method'        = 'Delete'
                    'URI'           = "$($connection.URI)/session"
                    'Headers'       = @{'X-Cookie' = "token=$($Connection.Token)"}
                    'ErrorVariable' = 'DisconnectError'
                    'ErrorAction'   = 'SilentlyContinue'
                }
                try {
                    $RemoveResponse = Invoke-RestMethod @RestMethodParams
                }
                catch {
                    Write-Verbose -Message "Session with Id $($connection.SessionId) seems to have expired."
                }


                Write-Verbose -message "Removing session from `$Global:NessusConn"
                $Global:NessusConn.Remove($Connection)
                Write-Verbose -Message "Session $($i) removed."
            }
        }
    }
}