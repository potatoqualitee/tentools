function Add-TNGroupUser {
    <#
    .SYNOPSIS
        Adds a user to a group

    .DESCRIPTION
        Adds a user to a group

    .PARAMETER GroupId
        Parameter description

    .PARAMETER UserId
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Add-TNGroupUser

    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Int32]$GroupId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Int32]$UserId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            if ($session.MultiUser) {
                $params = @{
                    SessionObject   = $session
                    Path            = "/groups/$GroupId/users"
                    Method          = 'POST'
                    Parameter       = @{'user_id' = $UserId }
                    EnableException = $EnableException
                }
                Invoke-TNRequest @params
            } else {
                Stop-PSFFunction -EnableException:$EnableException -Message "Server ($($session.ComputerName)) for session $($session.sessionid) is not licenced for multiple users" -Continue
            }
        }
    }
}