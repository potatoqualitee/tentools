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
        [int32[]]$SessionId
    )
    process {
        if ($Index.Count -gt 0) {
            foreach ($i in $SessionId) {
                foreach ($connection in $Global:NessusConn) {
                    if ($connection.SessionId -eq $i) {
                        $connection
                    }
                }
            }
        } else {
            # Return all sessions.
            $return_sessions = @()
            foreach ($s in $Global:NessusConn) {$s}
        }
    }
}