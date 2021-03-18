function Remove-TNGroupUser {
    <#
    .SYNOPSIS
        Removes a list of group users

    .DESCRIPTION
        Removes a list of group users

        Can be used to clear a previously defined, scan report altering rule

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER GroupId
        The ID of the target group

    .PARAMETER UserId
        The ID of the target user

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Remove-TNGroupUser -Id 500

        Deletes the group user with an ID of 500

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Int32]$GroupId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Int32]$UserId,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if ($session.MultiUser) {
                $groupparams = @{
                    SessionObject = $session
                    Path          = "/groups/$GroupId/users/$UserId"
                    Method        = 'DELETE'
                }

                Invoke-TNRequest @groupparams | ConvertFrom-TNRestResponse
            } else {
                Stop-PSFFunction -EnableException:$EnableException -Message "Server ($($session.ComputerName)) for session $($session.sessionid) is not licenced for multiple users" -Continue
            }
        }
    }
}