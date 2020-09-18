function Remove-ScGroupUser {
    <#
    .SYNOPSIS
        Removes a Nessus group user

    .DESCRIPTION
        Can be used to clear a previously defined, scan report altering rule

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-ScService.

    .PARAMETER Id
        ID number of the rule which would you like removed/deleted

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        Remove-ScGroupUser -SessionId 0 -Id 500
        Will delete a group user with an ID of 500

    .EXAMPLE
        Get-ScPluginRule -SessionId 0 | Remove-ScGroupUser
        Will delete all rules

    .EXAMPLE
        Get-ScPluginRule -SessionId 0 | ? {$_.Host -eq 'myComputer'} | Remove-ScGroupUser
        Will find all group users that match the computer name, and delete them

    .INPUTS
        Can accept pipeline data from Get-ScPluginRule

    .OUTPUTS
        Empty, unless an error is received from the server
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1)]
        [Int32]$GroupId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 2)]
        [Int32]$UserId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-ScSession -SessionId $SessionId)) {
            $serverparams = @{
                SessionObject = $session
                Path          = '/server/properties'
                Method        = 'GET'
            }

            $server = Invoke-ScRequest @serverparams

            if ($server.capabilities.multi_user -eq 'full') {
                $groupparams = @{
                    SessionObject = $session
                    Path          = "/groups/$($GroupId)/users/$($UserId)"
                    Method        = 'DELETE'
                }

                Invoke-ScRequest @groupparams
            }
            else {
                Write-PSFMessage -Level Warning -Message "Server for session $($session.sessionid) is not licenced for multiple users"
            }
        }
    }
}