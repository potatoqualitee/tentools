function Get-AcasSession {
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
        } else {
            # Return all sessions.
            $return_sessions = @()
            foreach ($s in $global:NessusConn) {$s}
        }
    }
}