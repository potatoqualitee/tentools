function Get-AcasSession {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        Parameter description

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
        if ($Index.Count -gt 0) {
            foreach ($id in $SessionId) {
                foreach ($connection in $global:NessusConn) {
                    if ($connection.SessionId -eq $id) {
                        $connection
                    }
                }
            }
        }
        else {
            # Return all sessions.
            $return_sessions = @()
            foreach ($s in $global:NessusConn) { $s }
        }
    }
}