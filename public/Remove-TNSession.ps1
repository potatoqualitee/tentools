function Remove-TNSession {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        Session ID

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TN
    #>
    [CmdletBinding()]
    param(
        [int[]]$SessionId,
        [switch]$EnableException
    )
    process {
        # Finding and saving sessions in to a different Array so they can be
        # removed from the main one so as to not generate an modification
        # error for a collection in use.
        $sessions = $script:NessusConn
        $toremove = New-Object -TypeName System.Collections.ArrayList

        if ($SessionId.Count -gt 0) {
            foreach ($id in $SessionId) {
                Write-PSFMessage -Level Verbose -Message "Removing server session $id"

                foreach ($session in $sessions) {
                    if ($session.SessionId -eq $id) {
                        [void]$toremove.Add($session)
                    }
                }
            }

            foreach ($session in $toremove) {
                Write-PSFMessage -Level Verbose -Message "Disposing of connection"
                $params = @{
                    SessionObject = $session
                    Method        = "DELETE"
                    URI           = "$($session.URI)/session"
                    Headers       = @{"X-Cookie" = "token=$($session.Token)" }
                    ErrorVariable = "DisconnectError"
                    ErrorAction   = "SilentlyContinue"
                }
                try {
                    Invoke-RestMethod @params
                } catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Session with Id $($session.SessionId) seems to have expired" -Continue
                }

                Write-PSFMessage -Level Verbose -Message "Removing session from `$script:NessusConn"
                $null = $script:NessusConn.Remove($session)
                Write-PSFMessage -Level Verbose -Message "Session $id removed"
            }
        }
    }
}