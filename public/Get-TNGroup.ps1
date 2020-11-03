function Get-TNGroup {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TN
    #>
    [CmdletBinding()]
    param
    (
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            if ($session.MultiUser) {
                $groupparams = @{
                    SessionObject = $session
                    Path          = '/groups'
                    Method        = 'GET'
                }

                Invoke-TNRequest @groupparams |
                    ConvertFrom-TNRestResponse

            } else {
                Stop-PSFFunction -EnableException:$EnableException -Message "Server ($($session.ComputerName)) for session $($session.sessionid) is not licenced for multiple users" -Continue
            }
        }
    }
}