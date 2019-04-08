function Remove-AcasSession {
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
    param(

        # Nessus session Id
        [Parameter(Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName)]
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
                Write-PSFMessage -Level Verbose -Mesage "Removing server session $($i)"

                foreach ($Connection in $connections) {
                    if ($Connection.SessionId -eq $i) {
                        [void]$toremove.Add($Connection)
                    }
                }
            }

            foreach ($Connection in $toremove) {
                Write-PSFMessage -Level Verbose -Mesage 'Disposing of connection'
                $RestMethodParams = @{
                    'Method'        = 'Delete'
                    'URI'           = "$($connection.URI)/session"
                    'Headers'       = @{'X-Cookie' = "token=$($Connection.Token)"}
                    'ErrorVariable' = 'DisconnectError'
                    'ErrorAction'   = 'SilentlyContinue'
                }
                try {
                    $RemoveResponse = Invoke-RestMethod @RestMethodParams
                } catch {
                    Write-PSFMessage -Level Verbose -Mesage "Session with Id $($connection.SessionId) seems to have expired."
                }


                Write-PSFMessage -Level Verbose -Mesage "Removing session from `$Global:NessusConn"
                $Global:NessusConn.Remove($Connection)
                Write-PSFMessage -Level Verbose -Mesage "Session $($i) removed."
            }
        }
    }
}