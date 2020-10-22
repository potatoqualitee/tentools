function Remove-TNGroupUser {
    <#
    .SYNOPSIS
        Removes a Nessus group user

    .DESCRIPTION
        Can be used to clear a previously defined, scan report altering rule

    .PARAMETER Id
        ID number of the rule which would you like removed/deleted

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        Remove-TNGroupUser -Id 500
        Will delete a group user with an ID of 500

    .EXAMPLE
        Get-TNPluginRule | Remove-TNGroupUser
        Will delete all rules

    .EXAMPLE
        Get-TNPluginRule | ? {$_.Host -eq 'myComputer'} | Remove-TNGroupUser
        Will find all group users that match the computer name, and delete them

    .INPUTS
        Can accept pipeline data from Get-TNPluginRule

    .OUTPUTS
        Empty, unless an error is received from the server
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
                $groupparams = @{
                    SessionObject = $session
                    Path          = "/groups/$GroupId/users/$UserId"
                    Method        = 'DELETE'
                }

                Invoke-TNRequest @groupparams
            } else {
                Write-PSFMessage -Level Warning -Message "Server ($($session.ComputerName)) for session $($session.sessionid) is not licenced for multiple users"
            }
        }
    }
}